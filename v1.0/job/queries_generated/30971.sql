WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.movie_id,
        ka.person_id,
        ka.name AS actor_name,
        1 AS level
    FROM 
        cast_info ca
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL

    UNION ALL

    SELECT 
        ca.movie_id,
        ka.person_id,
        ka.name,
        ah.level + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ca ON ah.movie_id = ca.movie_id
    JOIN 
        aka_name ka ON ca.person_id = ka.person_id
    WHERE 
        ka.name IS NOT NULL
),

MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        mt.title,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.movie_id, mt.title
),

MoviesWithCompanyInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        cn.name AS company_name,
        COUNT(mc.company_id) AS num_companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code IS NOT NULL
    GROUP BY 
        mt.movie_id, mt.title, cn.name
),

FinalResult AS (
    SELECT 
        a.movie_id,
        a.actor_name,
        mk.keywords,
        mc.title,
        mc.company_name,
        mc.num_companies,
        ROW_NUMBER() OVER(PARTITION BY a.movie_id ORDER BY a.level) AS actor_level
    FROM 
        ActorHierarchy a
    JOIN 
        MoviesWithKeywords mk ON a.movie_id = mk.movie_id
    JOIN 
        MoviesWithCompanyInfo mc ON a.movie_id = mc.movie_id
    WHERE 
        a.level = 1
)

SELECT 
    fr.movie_id,
    fr.actor_name,
    fr.keywords,
    fr.title,
    fr.company_name,
    fr.num_companies
FROM 
    FinalResult fr
WHERE 
    fr.num_companies > 0
ORDER BY 
    fr.movie_id, fr.actor_name;
