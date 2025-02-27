WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id 
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id 
    FROM 
        aka_title mt
    INNER JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),

TitleAndNames AS (
    SELECT 
        t.title,
        ak.name AS actor_name,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS name_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
),

KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    th.title,
    th.production_year,
    COALESCE(cs.company_count, 0) AS number_of_companies,
    cs.company_names,
    COALESCE(kc.keyword_count, 0) AS number_of_keywords,
    COUNT(DISTINCT tn.actor_name) AS actor_count,
    MAX(CASE WHEN tn.name_rank = 1 THEN tn.actor_name ELSE NULL END) AS first_actor,
    MAX(CASE WHEN tn.name_rank = 2 THEN tn.actor_name ELSE NULL END) AS second_actor,
    nh.level AS movie_level
FROM 
    MovieHierarchy nh
LEFT JOIN 
    TitleAndNames tn ON nh.movie_id = tn.movie_id
LEFT JOIN 
    CompanyStats cs ON nh.movie_id = cs.movie_id
LEFT JOIN 
    KeywordCount kc ON nh.movie_id = kc.movie_id
WHERE 
    nh.production_year >= 2000
GROUP BY 
    nh.movie_id, th.title, nh.production_year, cs.company_count, cs.company_names, kc.keyword_count, nh.level
HAVING 
    COUNT(DISTINCT tn.actor_name) > 1
ORDER BY 
    nh.production_year DESC, nh.title;
