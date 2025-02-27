WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS full_path
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 1990 AND 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        ml.title,
        ml.production_year,
        mh.level + 1 AS level,
        CAST(mh.full_path || ' -> ' || ml.title AS VARCHAR(255)) AS full_path
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.full_path,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS num_cast_members,
    AVG(CASE 
            WHEN ca.nr_order IS NOT NULL THEN ca.nr_order 
            ELSE 0 
        END) AS avg_order,
    STRING_AGG(DISTINCT cm.name, ', ') AS company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
WHERE 
    mh.level < 3
GROUP BY 
    mh.full_path, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
    AND MAX(mh.production_year) - MIN(mh.production_year) < 10
ORDER BY 
    mh.production_year DESC, num_cast_members DESC
LIMIT 10;

-- Testing NULL handling and bizarre scenarios
SELECT 
    ka.name AS aka_name,
    COALESCE(mu.title, 'Unknown Title') AS movie_title,
    COUNT(DISTINCT CASE WHEN ka.id IS NULL THEN 1 END) AS null_count,
    COUNT(DISTINCT mu.id) FILTER (WHERE mu.production_year IS NOT NULL) AS valid_movies
FROM 
    aka_name ka
LEFT JOIN 
    aka_title mu ON ka.id = mu.id AND ka.name IS NOT NULL
WHERE 
    (ka.name IS NULL OR ka.name <> '') 
    AND (mu.production_year IS NOT NULL OR mu.production_year IS NULL)
GROUP BY 
    ka.name, mu.title
HAVING 
    COUNT(mu.id) > 0
ORDER BY 
    null_count ASC;

