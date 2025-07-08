
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        COALESCE(mt.title, 'Unknown Title') AS title,
        mt.production_year,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        COALESCE(m.title, 'Unknown Title') AS title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        mh.depth < 3  
),

actor_movie AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ac.movie_id,
        at.title AS movie_title,
        at.production_year
    FROM 
        aka_name a
    JOIN 
        cast_info ac ON a.person_id = ac.person_id
    JOIN 
        aka_title at ON ac.movie_id = at.id
)

SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    COUNT(am.actor_id) AS Num_Actors,
    AVG(pm.info_length) AS Avg_Info_Length,
    LISTAGG(DISTINCT am.name, ', ') AS Actor_Names
FROM 
    movie_hierarchy mh
LEFT JOIN 
    actor_movie am ON mh.movie_id = am.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         LENGTH(info) AS info_length 
     FROM 
         movie_info 
     WHERE 
         info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis')
    ) pm ON mh.movie_id = pm.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(am.actor_id) > 5 AND 
    AVG(pm.info_length) IS NOT NULL 
ORDER BY 
    mh.production_year DESC, Num_Actors DESC;
