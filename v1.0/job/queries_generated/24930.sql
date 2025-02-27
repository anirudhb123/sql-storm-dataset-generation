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
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mm.id AS movie_id,
        mm.title,
        mm.production_year,
        mm.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mm ON ml.linked_movie_id = mm.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    p.name AS person_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    STRING_AGG(DISTINCT mh.title, ', ') AS movie_titles,
    MAX(mh.production_year) AS last_year,
    MIN(mh.production_year) AS first_year,
    CASE 
        WHEN COUNT(DISTINCT mh.movie_id) = 0 THEN 'No movies'
        ELSE 'Active'
    END AS activity_status,
    AVG(CASE 
        WHEN mh.production_year BETWEEN 2000 AND 2010 THEN 1
        ELSE NULL 
    END) AS avg_movies_2000s,
    SUM(CASE 
        WHEN mh.kind_id = 1 THEN 1 
        ELSE 0 
    END) AS count_feature_films,
    COUNT(DISTINCT ci.movie_id) AS total_casted_movies
FROM 
    aka_name p
LEFT JOIN 
    cast_info ci ON p.person_id = ci.person_id 
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id 
GROUP BY 
    p.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    total_movies DESC, 
    person_name
LIMIT 10;

-- Exploring anomalies in NULL handling with subqueries
SELECT 
    n.name,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mt.movie_id AND mi.info_type_id IS NULL) AS null_info_types,
    (SELECT COUNT(*) FROM movie_info_idx mii WHERE mii.movie_id = mt.movie_id AND mii.info IS NULL) AS null_indexes,
    COALESCE(n.gender, 'Unknown') AS gender_category
FROM 
    name n
JOIN 
    (SELECT DISTINCT movie_id FROM complete_cast cc WHERE cc.status_id IS NULL) mt ON mt.movie_id = n.id
WHERE 
    n.name LIKE 'A%'
AND 
    n.id NOT IN (SELECT person_id FROM person_info pi WHERE pi.info IS NULL)
ORDER BY 
    null_info_types DESC, 
    gender_category;
