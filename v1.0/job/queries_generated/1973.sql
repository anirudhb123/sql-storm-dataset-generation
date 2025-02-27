WITH MovieDetails AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT cc.subject_id) AS cast_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS has_roles_count
    FROM aka_title AS at
    LEFT JOIN complete_cast AS cc ON at.id = cc.movie_id
    LEFT JOIN cast_info AS ci ON cc.subject_id = ci.person_id
    WHERE at.production_year >= 2000
    GROUP BY at.id, at.title, at.production_year
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ak.name) AS role_rank
    FROM cast_info AS ci
    INNER JOIN aka_name AS ak ON ci.person_id = ak.person_id
    INNER JOIN aka_title AS at ON ci.movie_id = at.id
    WHERE ak.name IS NOT NULL
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        COUNT(DISTINCT mn.name) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM movie_companies AS mc
    INNER JOIN company_name AS cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.has_roles_count,
    cr.actor_name,
    cr.role_rank,
    cs.company_count,
    cs.company_names
FROM MovieDetails AS md
JOIN ActorRoles AS cr ON md.title = cr.movie_title
LEFT JOIN CompanyStats AS cs ON md.title = (
    SELECT at.title
    FROM aka_title AS at
    WHERE at.id = md.id
)
WHERE md.cast_count > 5
AND (md.has_roles_count IS NULL OR md.has_roles_count < 2)
ORDER BY md.production_year DESC, md.title;
