WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS hierarchy_level,
        mt.kind_id,
        mt.md5sum
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title AS title,
        a.production_year,
        mh.hierarchy_level + 1,
        a.kind_id,
        a.md5sum
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON a.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    ah.name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(CASE 
            WHEN COALESCE(mt.production_year, 0) = 0 THEN 0 
            ELSE (EXTRACT(YEAR FROM CURRENT_DATE) - mt.production_year) 
        END) AS average_age_of_movies,
    STRING_AGG(DISTINCT mt.title, '; ') AS titles,
    SUM(CASE 
            WHEN ci.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS notes_count,
    MAX(COALESCE(ci.nr_order, -1)) AS max_order
FROM 
    aka_name ah
LEFT JOIN 
    cast_info ci ON ah.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ah.name IS NOT NULL 
    AND LENGTH(ah.name) > 3 
    AND (mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Drama%')
         OR (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mt.id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')) > 0)
GROUP BY 
    ah.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    average_age_of_movies DESC, 
    notes_count DESC
LIMIT 10;

-- Additional benchmarking using window functions and null logic
WITH ranked_movies AS (
    SELECT 
        mt.id,
        mt.title,
        COALESCE(ci.nr_order, -1) AS role_order,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY COALESCE(ci.nr_order, -1)) AS movie_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
)
SELECT 
    rm.title,
    CASE 
        WHEN rm.role_order > 0 THEN 'Has order'
        WHEN rm.role_order IS NULL THEN 'No order assigned'
        ELSE 'Order less than zero'
    END AS order_status,
    COUNT(*) OVER () AS total_movies
FROM 
    ranked_movies rm
WHERE 
    rm.movie_rank <= 5 
ORDER BY 
    rm.title;
