WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ARRAY[m.id] AS movie_path
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.movie_path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        ml.link_type_id = (
            SELECT id 
            FROM link_type 
            WHERE link = 'Sequel'
        )
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE NULL END) AS avg_production_year,
    MAX(mh.movie_path) AS longest_chain
FROM 
    movie_keyword mk
JOIN 
    aka_title m ON mk.movie_id = m.id
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_hierarchy mh ON m.id = mh.movie_id
WHERE 
    mk.keyword IS NOT NULL
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    total_cast DESC;

-- Additional performance benchmarking:
EXPLAIN ANALYZE 
WITH movie_stats AS (
    SELECT 
        title.id,
        title.title,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        AVG(COALESCE(movie_info.info, 0)) AS avg_info_rating
    FROM 
        title 
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    GROUP BY 
        title.id
)
SELECT 
    ms.title,
    ms.actor_count,
    (CASE 
        WHEN ms.avg_info_rating IS NULL THEN 'No Ratings'
        WHEN ms.avg_info_rating >= 4 THEN 'High Rating'
        ELSE 'Low Rating' 
    END) AS rating_category
FROM 
    movie_stats ms
WHERE 
    ms.actor_count > 10;
