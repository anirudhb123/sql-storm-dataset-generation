WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 3
), 
actor_movie AS (
    SELECT 
        ca.person_id,
        at.id AS movie_id,
        at.title,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY at.production_year DESC) AS rn
    FROM 
        cast_info ca
    JOIN 
        aka_title at ON ca.movie_id = at.id
    WHERE 
        ca.nr_order <= 3
), 
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        a.movie_id,
        a.title,
        a.rn,
        CASE 
            WHEN a.rn IS NULL THEN 'Unknown'
            ELSE ak.name 
        END AS valid_actor_name
    FROM 
        actor_movie a
    LEFT JOIN 
        aka_name ak ON a.person_id = ak.person_id
), 
popular_keywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
    ORDER BY 
        COUNT(*) DESC
)
SELECT 
    mh.title AS movie_title,
    COALESCE(ai.actor_name, 'No Actor') AS lead_actor,
    k.keyword AS popular_keyword,
    mh.production_year,
    mh.level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_info ai ON mh.movie_id = ai.movie_id AND ai.rn = 1
LEFT JOIN 
    popular_keywords k ON mh.movie_id = k.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2023
ORDER BY 
    mh.production_year DESC,
    mh.title,
    mh.level DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;

