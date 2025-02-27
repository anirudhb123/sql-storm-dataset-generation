WITH RECURSIVE ActorHierarchy AS (
    SELECT
        ci.person_id,
        a.name,
        1 AS level
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2000)
    
    UNION ALL
    
    SELECT
        ci.person_id,
        a.name,
        ah.level + 1
    FROM
        cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN ActorHierarchy ah ON ci.movie_id IN (
        SELECT movie_id 
        FROM complete_cast cc 
        WHERE cc.subject_id = ah.person_id
    )
),
MovieDetails AS (
    SELECT
        at.title,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM
        aka_title at
    LEFT JOIN cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY
        at.title, at.production_year
),
CompanyInfo AS (
    SELECT
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM
        movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY
        mc.movie_id
)
SELECT
    md.title,
    md.actors,
    md.production_year,
    ci.companies,
    COALESCE(SUM(CASE WHEN ah.level = 1 THEN 1 ELSE 0 END), 0) AS top_billed_count,
    COALESCE(SUM(CASE WHEN ah.level > 1 THEN 1 ELSE 0 END), 0) AS supporting_count
FROM
    MovieDetails md
LEFT JOIN CompanyInfo ci ON md.title IN (SELECT title FROM aka_title WHERE movie_id = ci.movie_id)
LEFT JOIN ActorHierarchy ah ON md.actors LIKE '%' || ah.name || '%'
WHERE
    md.production_year BETWEEN 2010 AND 2020
GROUP BY
    md.title, md.actors, md.production_year, ci.companies
ORDER BY
    md.production_year DESC, md.rank ASC;
