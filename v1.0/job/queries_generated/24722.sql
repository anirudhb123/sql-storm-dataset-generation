WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(mt.episode_of_id, mt.id) AS root_movie,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(m.episode_of_id, m.id),
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_hierarchy mh ON m.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COALESCE(k.keyword, 'No Keyword') AS movie_keyword,
    GROUP_CONCAT(DISTINCT ch.name) AS character_names,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    MAX(mh.production_year) AS latest_movie_year,
    AVG(CASE 
            WHEN ct.kind = 'Director' THEN 1 
            ELSE 0 
        END) AS director_ratio,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mh.depth ASC) AS movie_rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
LEFT JOIN 
    aka_title at ON mc.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    char_name ch ON ci.person_role_id = ch.id
LEFT JOIN 
    comp_cast_type ct ON ci.role_id = ct.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    ak.name NOT LIKE '%(uncredited)%' 
    AND mh.production_year >= 2000
    AND NOT EXISTS (
        SELECT 1
        FROM person_info pi
        WHERE pi.person_id = ak.person_id
        AND pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Deceased')
    )
GROUP BY 
    ak.name, k.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    latest_movie_year DESC, total_movies DESC
LIMIT 50 OFFSET 10;
