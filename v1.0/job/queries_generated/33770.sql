WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.depth < 3
),
popular_actors AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies
    FROM 
        cast_info ci
    JOIN 
        movie_hierarchy mh ON ci.movie_id = mh.movie_id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
actor_names AS (
    SELECT 
        ka.person_id,
        STRING_AGG(ka.name, ', ') AS actor_names
    FROM 
        aka_name ka
    JOIN 
        popular_actors pa ON ka.person_id = pa.person_id
    GROUP BY 
        ka.person_id
),
movies_with_details AS (
    SELECT 
        mh.title AS movie_title,
        mh.depth,
        COALESCE(an.actor_names, 'Unknown Actor') AS actor_names,
        mt.production_year,
        COUNT(DISTINCT mk.keyword_id) AS keywords_count
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        actor_names an ON mh.movie_id IN (
            SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = an.person_id
        )
    JOIN 
        aka_title mt ON mh.movie_id = mt.id
    GROUP BY 
        mh.title, mh.depth, an.actor_names, mt.production_year
)
SELECT 
    m.movie_title,
    m.depth,
    m.actor_names,
    m.production_year,
    m.keywords_count,
    ROW_NUMBER() OVER (PARTITION BY m.depth ORDER BY m.keywords_count DESC) AS rank_by_keywords
FROM 
    movies_with_details m
WHERE 
    m.production_year IS NOT NULL
ORDER BY 
    m.depth, 
    m.keywords_count DESC;
