use crate::db::DbConn;
use crate::routes::lifepaths::LifepathFilters;
use crate::schema;
use crate::schema::StatMod;
use diesel::pg::expression::dsl::any;
use diesel::prelude::*;

pub trait LifepathRepo {
    fn lifepaths(&self, filters: &LifepathFilters) -> LifepathRepoResult<Vec<LifepathRow>>;
    fn lifepath_skills(&self, lifepath_ids: &[i32]) -> LifepathRepoResult<Vec<LifepathSkillRow>>;
    fn lifepath_traits(&self, lifepath_ids: &[i32]) -> LifepathRepoResult<Vec<LifepathTraitRow>>;
    fn lifepath_leads(&self, lifepath_ids: &[i32]) -> LifepathRepoResult<Vec<LeadRow>>;
}

const LIFEPATH_LIMIT: i64 = 20;

impl LifepathRepo for DbConn {
    fn lifepaths(&self, filters: &LifepathFilters) -> LifepathRepoResult<Vec<LifepathRow>> {
        use schema::lifepaths::dsl::*;

        let mut query = lifepaths
            .select((
                id,
                lifepath_setting_id,
                page,
                name,
                years,
                gen_skill_pts,
                skill_pts,
                trait_pts,
                stat_mod,
                stat_mod_val,
                res,
            ))
            .into_boxed();

        if let Some(born_filter) = filters.born {
            query = query.filter(born.eq(born_filter));
        }

        if let Some(setting_ids) = &filters.setting_ids {
            query = query.filter(lifepath_setting_id.eq(any(setting_ids)))
        }

        let rows = query.limit(LIFEPATH_LIMIT).load(&**self)?;
        Ok(rows)
    }

    fn lifepath_skills(
        &self,
        lifepath_ids: &[i32],
    ) -> Result<Vec<LifepathSkillRow>, LifepathRepoError> {
        use schema::lifepath_skill_lists as skill_lists;
        use schema::skills;

        let rows = skill_lists::table
            .inner_join(skills::table)
            .select((
                skill_lists::entryless_skill,
                skills::name,
                skill_lists::skill_id,
                skills::page,
                skills::magical,
                skills::training,
                skills::wise,
                skill_lists::lifepath_id,
            ))
            .filter(skill_lists::skill_id.eq(skills::id))
            .filter(skill_lists::lifepath_id.eq(any(lifepath_ids)))
            .order_by(skill_lists::lifepath_id)
            .then_order_by(skill_lists::list_position)
            .load::<LifepathSkillRow>(&**self)?;

        Ok(rows)
    }

    fn lifepath_traits(&self, lifepath_ids: &[i32]) -> LifepathRepoResult<Vec<LifepathTraitRow>> {
        use schema::lifepath_trait_lists as trait_lists;
        use schema::traits;

        let rows = trait_lists::table
            .left_join(traits::table)
            .select((
                trait_lists::lifepath_id,
                trait_lists::char_trait,
                trait_lists::trait_id,
                traits::name.nullable(),
                traits::page.nullable(),
                traits::cost.nullable(),
                traits::typ.nullable(),
            ))
            .filter(
                trait_lists::trait_id
                    .eq(traits::id.nullable())
                    .or(trait_lists::trait_id.is_null()),
            )
            .filter(trait_lists::lifepath_id.eq(any(lifepath_ids)))
            .order_by(trait_lists::lifepath_id)
            .then_order_by(trait_lists::list_position)
            .load::<LifepathTraitRow>(&**self)?;

        Ok(rows)
    }

    fn lifepath_leads(&self, lifepath_ids: &[i32]) -> Result<Vec<LeadRow>, LifepathRepoError> {
        use schema::leads;
        use schema::lifepath_settings as settings;

        let rows = leads::table
            .inner_join(settings::table)
            .select((
                leads::lifepath_id,
                leads::setting_id,
                settings::name,
                settings::page,
            ))
            .filter(leads::setting_id.eq(settings::id))
            .filter(leads::lifepath_id.eq(any(lifepath_ids)))
            .order_by(leads::lifepath_id)
            .load::<LeadRow>(&**self)?;

        Ok(rows)
    }
}

type LifepathRepoResult<T> = Result<T, LifepathRepoError>;

pub enum LifepathRepoError {
    Useless,
}

impl From<diesel::result::Error> for LifepathRepoError {
    fn from(_err: diesel::result::Error) -> Self {
        LifepathRepoError::Useless
    }
}

#[derive(Queryable, Debug)]
pub struct LeadRow {
    pub lifepath_id: i32,
    pub setting_id: i32,
    pub setting_name: String,
    pub setting_page: i32,
}

#[derive(Queryable, Debug)]
pub struct LifepathRow {
    pub id: i32,
    pub lifepath_setting_id: i32,
    pub page: i32,
    pub name: String,
    pub years: Option<i32>,
    pub gen_skill_pts: Option<i32>,
    pub skill_pts: i32,
    pub trait_pts: i32,
    pub stat_mod: Option<StatMod>,
    pub stat_mod_val: Option<i32>,
    pub res: Option<i32>,
}

#[derive(Queryable, Debug)]
pub struct LifepathSkillRow {
    pub entryless_skill: Option<String>,
    pub name: String,
    pub skill_id: i32,
    pub page: i32,
    pub magical: bool,
    pub training: bool,
    pub wise: bool,
    pub lifepath_id: i32,
}

#[derive(Queryable, Debug)]
pub struct LifepathTraitRow {
    pub lifepath_id: i32,
    pub char_trait: Option<String>,
    pub trait_id: Option<i32>,
    pub name: Option<String>,
    pub page: Option<i32>,
    pub cost: Option<i32>,
    pub typ: Option<schema::TraitType>,
}
