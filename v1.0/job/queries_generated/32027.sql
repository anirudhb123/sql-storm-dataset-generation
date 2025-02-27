WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

popular_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        movie_hierarchy mh
    JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),

actor_names AS (
    SELECT
        ak.name,
        ak.person_id,
        c.movie_id
    FROM
        aka_name ak
    JOIN
        cast_info c ON ak.person_id = c.person_id
    WHERE
        ak.name IS NOT NULL
),

ranked_movies AS (
    SELECT
        pm.movie_id,
        pm.title,
        pm.production_year,
        RANK() OVER (ORDER BY pm.cast_count DESC) AS ranking
    FROM 
        popular_movies pm
)

SELECT 
    rm.title,
    rm.production_year,
    rn.name AS actor_name,
    rm.ranking,
    COALESCE(k.keyword, 'No Keywords') AS keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    actor_names rn ON rm.movie_id = rn.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.ranking <= 10
ORDER BY 
    rm.ranking, rm.production_year DESC, rn.name;
