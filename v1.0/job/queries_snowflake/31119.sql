
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        CAST(NULL AS INTEGER) AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title e
    INNER JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
actors_count AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
detailed_movie_info AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mk.keywords, '') AS keywords
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        actors_count ac ON mh.movie_id = ac.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON mh.movie_id = mk.movie_id
)
SELECT 
    dmi.title,
    dmi.production_year,
    dmi.actor_count,
    CASE 
        WHEN dmi.actor_count = 0 THEN 'No actors'
        ELSE 'Actors available'
    END AS actor_availability,
    CASE 
        WHEN dmi.production_year < 2000 THEN 'Old Movie'
        WHEN dmi.production_year BETWEEN 2000 AND 2010 THEN 'Early 2000s'
        ELSE 'Modern Movie'
    END AS movie_age,
    ROW_NUMBER() OVER (PARTITION BY dmi.production_year ORDER BY dmi.actor_count DESC) AS rank_within_year
FROM 
    detailed_movie_info dmi
WHERE 
    dmi.actor_count > 0
ORDER BY 
    dmi.actor_count DESC,
    dmi.title;
