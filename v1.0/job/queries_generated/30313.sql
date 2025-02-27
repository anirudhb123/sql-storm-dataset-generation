WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        CONCAT('Sequel to: ', mh.title),
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.depth < 5 
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(w.rank, 0) AS rank,
    movie_years.production_year,
    COUNT(DISTINCT m.keyword_id) AS keyword_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_info_idx movie_years ON movie_years.movie_id = at.id AND movie_years.info_type_id = (SELECT id FROM info_type WHERE info = 'year')
LEFT JOIN 
    movie_keyword m ON m.movie_id = at.id
LEFT JOIN 
    (SELECT 
        movie_id,
        RANK() OVER (PARTITION BY kind_id ORDER BY COUNT(*) DESC) AS rank
     FROM 
        movie_info 
     WHERE 
        info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
     GROUP BY 
        movie_id
    ) w ON w.movie_id = at.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = at.id
WHERE 
    ak.name IS NOT NULL
    AND movie_years.info IS NOT NULL
    AND (at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short')) OR at.production_year > 2010)
GROUP BY 
    ak.name, at.title, w.rank, movie_years.production_year
HAVING 
    COUNT(DISTINCT m.keyword_id) > 2 
ORDER BY 
    rank DESC, movie_title ASC
LIMIT 50;
