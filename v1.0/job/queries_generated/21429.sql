WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        movie_id, 
        title_id AS parent_id, 
        1 AS depth
    FROM 
        aka_title
    WHERE 
        production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.movie_id, 
        mh.movie_id AS parent_id, 
        mh.depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.linked_movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)

, filtered_titles AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        hk.keyword AS high_keyword,
        'High Rating: ' || CAST(r.rating AS TEXT) AS custom_rating,
        COALESCE(ak.name, 'Unknown') AS actor_name
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        (SELECT 
             movie_id, 
             AVG(rating) AS rating 
         FROM 
             movie_info 
         WHERE 
             note IS NULL 
         GROUP BY 
             movie_id
        ) r ON mt.id = r.movie_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword hk ON mk.keyword_id = hk.id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mk.keyword_id IS NOT NULL
        AND (mt.production_year > 2010 OR ak.name IS NOT NULL)

    QUALIFY 
        RANK() OVER (PARTITION BY mt.id ORDER BY r.rating DESC) = 1
) 

SELECT DISTINCT 
    ft.movie_id, 
    ft.title, 
    ft.high_keyword, 
    ft.custom_rating, 
    mh.depth,
    CASE WHEN ft.actor_name IS NULL THEN 'No Actors' ELSE ft.actor_name END AS actor_name 
FROM 
    filtered_titles ft
FULL OUTER JOIN 
    movie_hierarchy mh ON ft.movie_id = mh.movie_id
WHERE 
    mh.depth IS NOT NULL OR ft.high_keyword IS NOT NULL
ORDER BY 
    ft.title, mh.depth DESC NULLS LAST;


