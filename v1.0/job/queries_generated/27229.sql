WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        title.id AS movie_id, 
        title.title,
        title.production_year,
        ARRAY[title.title] AS title_path
    FROM 
        title
    WHERE 
        title.id IN (SELECT linked_movie_id FROM movie_link WHERE link_type_id = (SELECT id FROM link_type WHERE link = 'sequel'))

    UNION ALL

    SELECT 
        linked.title.id AS movie_id, 
        linked.title.title,
        linked.title.production_year,
        mh.title_path || linked.title.title
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        title linked ON ml.linked_movie_id = linked.id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'sequel')
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(mh.title || ' (' || m.production_year || ')') AS sequels,
    COUNT(DISTINCT ki.keyword) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, m.title, m.production_year
ORDER BY 
    actor_name, movie_title;
