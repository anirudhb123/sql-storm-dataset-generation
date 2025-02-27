WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actor_role_summary AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        STRING_AGG(DISTINCT title.title, ', ') AS movies_directed
    FROM 
        cast_info c
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    INNER JOIN 
        aka_title title ON c.movie_id = title.movie_id
    GROUP BY 
        a.person_id
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_company_info AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT c.name) AS companies
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.id
)
SELECT 
    mh.title,
    mh.production_year,
    mh.level,
    ars.person_id,
    ars.movie_count,
    k.keywords,
    mci.companies
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_role_summary ars ON mh.movie_id = ars.movie_id
LEFT JOIN 
    keyword_summary k ON mh.movie_id = k.movie_id
LEFT JOIN 
    movie_company_info mci ON mh.movie_id = mci.movie_id
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.level, ars.movie_count DESC
LIMIT 10;
