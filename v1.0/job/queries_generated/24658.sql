WITH RecursiveMovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT c.id) OVER (PARTITION BY m.id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS actor_order
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        cast_info AS c ON m.id = c.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        MIN(ct.kind) AS primary_company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
ActorInfo AS (
    SELECT 
        pi.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY pi.person_id ORDER BY pi.info_type_id) AS info_rank,
        MAX(CASE WHEN it.info = 'Birthday' THEN pi.info END) AS birthday,
        MAX(CASE WHEN it.info = 'Death' THEN pi.info END) AS death_date
    FROM 
        person_info AS pi
    JOIN 
        name AS a ON pi.person_id = a.imdb_id
    JOIN 
        info_type AS it ON pi.info_type_id = it.id
    GROUP BY 
        pi.person_id, a.name
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keyword,
    r.actor_count,
    r.actor_order,
    COALESCE(c.companies, '{}') AS companies,
    c.primary_company_type,
    a.name AS actor_name,
    a.birthday,
    a.death_date
FROM 
    RecursiveMovieInfo AS r
LEFT JOIN 
    CompanyInfo AS c ON r.movie_id = c.movie_id
LEFT JOIN 
    cast_info AS ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    ActorInfo AS a ON ci.person_id = a.person_id
WHERE 
    a.info_rank = 1 OR a.info_rank IS NULL
ORDER BY 
    r.production_year DESC, r.title;
