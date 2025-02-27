WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.nr_order = 1 -- Start with the main cast

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
    WHERE 
        c.nr_order > 1 -- Find supporting actors recursively
),
TitleInfo AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    th.movie_title,
    th.production_year,
    ah.actor_name,
    cd.companies,
    cd.company_types,
    COALESCE(GROUP_CONCAT(DISTINCT ti.movie_keyword), 'N/A') AS keywords,
    COUNT(DISTINCT ah.person_id) OVER(PARTITION BY ah.person_id) AS collaborated_movies
FROM 
    TitleInfo ti
JOIN 
    TitleInfo th ON th.production_year = ti.production_year AND th.keyword_rank = 1
LEFT JOIN 
    ActorHierarchy ah ON ah.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = th.id)
LEFT JOIN 
    CompanyDetails cd ON cd.movie_id = th.id
WHERE 
    th.production_year IS NOT NULL
    AND (ti.movie_keyword IS NOT NULL OR cd.companies IS NOT NULL)
ORDER BY 
    th.production_year DESC, 
    th.movie_title;
