WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS movie_titles,
    MAX(mt.production_year) AS latest_movie_year,
    SUM(CASE 
            WHEN mt.production_year IS NULL THEN 1 
            ELSE 0 
        END) AS null_year_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;

-- Benchmarking query with usage of correlated subquery for actor movie count
SELECT 
    a.person_id,
    a.name,
    (SELECT COUNT(*)
     FROM cast_info ci_sub
     WHERE ci_sub.person_id = a.person_id) AS total_movies,
    (SELECT COUNT(DISTINCT mt.production_year)
     FROM cast_info ci_sub
     JOIN aka_title mt ON ci_sub.movie_id = mt.id
     WHERE ci_sub.person_id = a.person_id AND mt.production_year IS NOT NULL) AS unique_years_active
FROM 
    aka_name a
WHERE 
    a.person_id IN (SELECT DISTINCT person_id FROM cast_info)
ORDER BY 
    unique_years_active DESC
LIMIT 5;
