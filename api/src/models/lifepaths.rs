use crate::repos::lifepaths::*;
use crate::schema;
use itertools::Itertools;
use std::collections::HashMap;
use std::convert::Into;

pub struct Lifepaths;

impl Lifepaths {
    pub fn born(db: impl LifepathRepo) -> Result<Vec<Lifepath>, LifepathsError> {
        let born_lps = db.born_lifepaths()?;
        let lifepath_ids: Vec<_> = born_lps.iter().map(|lp| lp.id).collect();

        let skill_rows = db.lifepath_skills(&lifepath_ids)?;
        let mut skill_lists = group_skill_lists(skill_rows);

        let lead_rows = db.lifepath_leads(&lifepath_ids)?;
        let mut leads = group_leads(lead_rows);

        born_lps
            .into_iter()
            .map(|row| to_lifepath(row, &mut skill_lists, &mut leads))
            .collect()
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

fn to_lifepath(
    row: LifepathRow,
    skill_lists: &mut HashMap<i32, Vec<Skill>>,
    leads: &mut HashMap<i32, Vec<Lead>>,
) -> Result<Lifepath, LifepathsError> {
    let stat_mod = stat_mod(&row)?;
    let years = row.years.ok_or(LifepathsError::Useless)?;
    let res = row.res.ok_or(LifepathsError::Useless)?;

    let skills = skill_lists.remove(&row.id).unwrap_or_default();
    let leads = leads.remove(&row.id).unwrap_or_default();

    Ok(Lifepath {
        id: row.id,
        name: row.name,
        page: row.page,
        years,
        stat_mod,
        res,
        leads,
        gen_skill_pts: row.gen_skill_pts,
        skill_pts: row.skill_pts,
        trait_pts: row.trait_pts,
        skills,
    })
}

fn stat_mod(row: &LifepathRow) -> Result<StatMod, LifepathsError> {
    use schema::StatMod as SchemaMod;
    use StatMod::*;

    let result = if let Some(stat_mod) = row.stat_mod {
        let val = row.stat_mod_val.ok_or(LifepathsError::Useless)?;

        match stat_mod {
            SchemaMod::Physical => Physical(val),
            SchemaMod::Mental => Mental(val),
            SchemaMod::Both => Both(val),
            SchemaMod::Either => Either(val),
        }
    } else {
        StatMod::None
    };

    Ok(result)
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Lifepath {
    pub id: i32,
    pub name: String,
    pub page: i32,
    pub years: i32,
    pub stat_mod: StatMod,
    pub res: i32,
    pub leads: Vec<Lead>,
    pub gen_skill_pts: i32,
    pub skill_pts: i32,
    pub trait_pts: i32,
    pub skills: Vec<Skill>,
}

#[derive(Debug, Serialize, Deserialize)]
pub enum StatMod {
    Physical(i32),
    Mental(i32),
    Either(i32),
    Both(i32),
    None,
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

pub enum LifepathsError {
    Useless,
}

impl From<LifepathRepoError> for LifepathsError {
    fn from(_err: LifepathRepoError) -> Self {
        Self::Useless
    }
}
