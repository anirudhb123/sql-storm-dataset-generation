WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        title.imdb_index,
        1 AS level
    FROM 
        title
    WHERE 
        title.episode_of_id IS NULL

    UNION ALL

    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.imdb_index,
        mh.level + 1
    FROM 
        title t
    INNER JOIN 
        movie_link ml ON t.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(person.name, 'Unknown') AS actor_name,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    AVG(CHAR_LENGTH(m.title)) OVER (PARTITION BY m.production_year) AS avg_title_length,
    CASE 
        WHEN ic.info IS NOT NULL THEN 'Has Info'
        ELSE 'No Info'
    END AS info_presence
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name person ON ci.person_id = person.person_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = m.movie_id
LEFT JOIN 
    movie_info_idx ic ON ic.movie_id = m.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    m.movie_id, person.name, ic.info
ORDER BY 
    m.production_year DESC, keyword_count DESC;
