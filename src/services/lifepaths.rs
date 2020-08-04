use crate::repos::lifepaths::*;
use crate::routes::lifepaths::LifepathFilters;
use crate::schema;
use itertools::Itertools;
use std::collections::HashMap;
use std::convert::{Into, TryFrom, TryInto};

pub struct Lifepaths;

impl Lifepaths {
    pub fn list(
        db: impl LifepathRepo,
        filters: &LifepathFilters,
    ) -> LifepathsResult<Vec<Lifepath>> {
        let lp_rows = db.lifepaths(filters)?;
        let lifepath_ids: Vec<_> = lp_rows.iter().map(|lp| lp.id).collect();

        let skill_rows = db.lifepath_skills(&lifepath_ids)?;
        let mut skill_lists = group_skill_lists(skill_rows);

        let trait_rows = db.lifepath_traits(&lifepath_ids)?;
        let mut trait_lists = group_trait_lists(trait_rows)?;

        let lead_rows = db.lifepath_leads(&lifepath_ids)?;
        let mut leads = group_leads(lead_rows);

        let req_rows = db.lifepath_reqs(&lifepath_ids)?;
        let mut reqs = group_requirements(req_rows)?;

        let to_lifepath = |row| {
            add_associations(
                row,
                &mut skill_lists,
                &mut trait_lists,
                &mut leads,
                &mut reqs,
            )
        };

        lp_rows.into_iter().map(to_lifepath).collect()
    }
}

fn group_trait_lists(rows: Vec<LifepathTraitRow>) -> LifepathsResult<HashMap<i32, Vec<Trait>>> {
    rows.into_iter()
        .group_by(|row| row.lifepath_id)
        .into_iter()
        .map(convert_trait_rows)
        .collect()
}

fn convert_trait_rows(
    (id, rows): (i32, impl Iterator<Item = LifepathTraitRow>),
) -> LifepathsResult<(i32, Vec<Trait>)> {
    let traits: Result<_, LifepathsError> = rows.map(TryInto::try_into).collect();
    Ok((id, traits?))
}

fn group_requirements(rows: Vec<LifepathReqRow>) -> LifepathsResult<HashMap<i32, Requirement>> {
    rows.into_iter()
        .group_by(|row| row.lifepath_id)
        .into_iter()
        .map(convert_req_rows)
        .collect()
}

fn convert_req_rows(
    (id, rows): (i32, impl Iterator<Item = LifepathReqRow>),
) -> LifepathsResult<(i32, Requirement)> {
    let mut reqs: Vec<Requirement> = rows.map(Into::into).collect();

    if reqs.len() == 1 {
        Ok((id, reqs.remove(0)))
    } else {
        Err(LifepathsError::Useless)
    }
}

fn group_skill_lists(rows: Vec<LifepathSkillRow>) -> HashMap<i32, Vec<Skill>> {
    rows.into_iter()
        .group_by(|row| row.lifepath_id)
        .into_iter()
        .map(|(id, rows)| (id, rows.map(Into::into).collect()))
        .collect()
}

fn group_leads(rows: Vec<LeadRow>) -> HashMap<i32, Vec<Lead>> {
    rows.into_iter()
        .group_by(|row| row.lifepath_id)
        .into_iter()
        .map(|(id, rows)| (id, rows.map(Into::into).collect()))
        .collect()
}

fn add_associations(
    row: LifepathRow,
    skill_lists: &mut HashMap<i32, Vec<Skill>>,
    trait_lists: &mut HashMap<i32, Vec<Trait>>,
    leads: &mut HashMap<i32, Vec<Lead>>,
    reqs: &mut HashMap<i32, Requirement>,
) -> LifepathsResult<Lifepath> {
    let stat_mod = stat_mod(&row)?;
    let years = row.years.ok_or(LifepathsError::Useless)?;
    let res = row.res.ok_or(LifepathsError::Useless)?;
    let gen_skill_pts = row.gen_skill_pts.ok_or(LifepathsError::Useless)?;

    let skills = skill_lists.remove(&row.id).unwrap_or_default();
    let traits = trait_lists.remove(&row.id).unwrap_or_default();
    let leads = leads.remove(&row.id).unwrap_or_default();
    let requirement = reqs.remove(&row.id);

    Ok(Lifepath {
        id: row.id,
        setting_id: row.lifepath_setting_id,
        setting_name: row.setting_name,
        name: row.name,
        page: row.page,
        years,
        stat_mod,
        res,
        leads,
        gen_skill_pts,
        skill_pts: row.skill_pts,
        trait_pts: row.trait_pts,
        skills,
        traits,
        born: row.born,
        requirement,
    })
}

fn stat_mod(row: &LifepathRow) -> LifepathsResult<Option<StatMod>> {
    use schema::StatMod as SchemaMod;
    use StatMod::*;

    let result = if let Some(stat_mod) = row.stat_mod {
        let val = row.stat_mod_val.ok_or(LifepathsError::Useless)?;

        Some(match stat_mod {
            SchemaMod::Physical => Physical(val),
            SchemaMod::Mental => Mental(val),
            SchemaMod::Both => Both(val),
            SchemaMod::Either => Either(val),
        })
    } else {
        None
    };

    Ok(result)
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Lifepath {
    pub id: i32,
    pub setting_id: i32,
    pub setting_name: String,
    pub name: String,
    pub page: i32,
    pub years: i32,
    pub stat_mod: Option<StatMod>,
    pub res: i32,
    pub leads: Vec<Lead>,
    pub gen_skill_pts: i32,
    pub skill_pts: i32,
    pub trait_pts: i32,
    pub skills: Vec<Skill>,
    pub traits: Vec<Trait>,
    pub born: bool,
    pub requirement: Option<Requirement>,
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type", content = "value")]
pub enum StatMod {
    Physical(i32),
    Mental(i32),
    Either(i32),
    Both(i32),
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Lead {
    pub setting_name: String,
    pub setting_id: i32,
    pub setting_page: i32,
}

impl From<LeadRow> for Lead {
    fn from(row: LeadRow) -> Self {
        Lead {
            setting_name: row.setting_name,
            setting_id: row.setting_id,
            setting_page: row.setting_page,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Skill {
    pub display_name: String,
    pub page: i32,
    pub skill_id: i32,
    pub magical: bool,
    pub training: bool,
    pub wise: bool,
}

impl From<LifepathSkillRow> for Skill {
    fn from(row: LifepathSkillRow) -> Self {
        Skill {
            display_name: row.entryless_skill.unwrap_or(row.name),
            page: row.page,
            skill_id: row.skill_id,
            magical: row.magical,
            training: row.training,
            wise: row.wise,
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
#[serde(tag = "type", content = "value")]
pub enum Trait {
    TraitEntry {
        name: String,
        trait_id: i32,
        page: i32,
        cost: Option<i32>,
        taip: schema::TraitType,
    },

    CharTrait {
        name: String,
    },
}

impl TryFrom<LifepathTraitRow> for Trait {
    type Error = LifepathsError;

    fn try_from(row: LifepathTraitRow) -> Result<Self, Self::Error> {
        if let Some(trait_id) = row.trait_id {
            let missing = |col| {
                LifepathsError::MissingValue(format!(
                    "Missing {} for lifepath_trait {}",
                    col, trait_id
                ))
            };

            let name = row.name.ok_or_else(|| missing("name"))?;
            let page = row.page.ok_or_else(|| missing("page"))?;
            let taip = row.taip.ok_or_else(|| missing("taip"))?;
            let cost = row.cost;

            Ok(Trait::TraitEntry {
                name,
                trait_id,
                page,
                cost,
                taip,
            })
        } else {
            let lifepath_id = row.lifepath_id;
            let name = row.char_trait.ok_or_else(|| {
                LifepathsError::MissingValue(format!(
                    "Missing char_trait for lifepath_trait with lifepath_id {}",
                    lifepath_id
                ))
            })?;

            Ok(Trait::CharTrait { name })
        }
    }
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Requirement {
    predicate: ReqPredicate,
    description: String,
}

impl From<LifepathReqRow> for Requirement {
    fn from(row: LifepathReqRow) -> Self {
        Requirement {
            predicate: row.predicate,
            description: row.description,
        }
    }
}

pub type LifepathsResult<T> = Result<T, LifepathsError>;

pub enum LifepathsError {
    Useless,
    MissingValue(String),
    InvalidJson,
}

impl From<LifepathRepoError> for LifepathsError {
    fn from(_err: LifepathRepoError) -> Self {
        Self::Useless
    }
}

impl From<serde_json::Error> for LifepathsError {
    fn from(_err: serde_json::Error) -> Self {
        Self::InvalidJson
    }
}
