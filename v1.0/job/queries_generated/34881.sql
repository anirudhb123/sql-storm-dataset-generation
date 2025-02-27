WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        m.title as linked_movie_title,
        1 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        mh.movie_title,
        mh.production_year,
        m.title as linked_movie_title,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_title = (SELECT title FROM aka_title WHERE id = ml.movie_id)
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT mh.linked_movie_title) AS number_of_linked_movies,
    MAX(mh.depth) AS max_depth
FROM 
    MovieHierarchy mh
GROUP BY 
    mh.movie_title, mh.production_year
HAVING 
    COUNT(DISTINCT mh.linked_movie_title) > 5
ORDER BY 
    mh.production_year DESC, number_of_linked_movies DESC;

WITH TotalCast AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast_count,
        COUNT(DISTINCT ci.role_id) AS distinct_roles 
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
HighProfileActors AS (
    SELECT 
        ak.name AS actor_name,
        ci.movie_id
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name ILIKE '%Tom Hanks%'
),
MoviesWithActors AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        tc.total_cast_count,
        ha.actor_name
    FROM 
        aka_title m
    JOIN 
        TotalCast tc ON m.id = tc.movie_id
    JOIN 
        HighProfileActors ha ON m.id = ha.movie_id
)
SELECT 
    mw.movie_title, 
    mw.total_cast_count,
    CASE 
        WHEN mw.total_cast_count > 30 THEN 'Large Cast'
        WHEN mw.total_cast_count BETWEEN 15 AND 30 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size 
FROM 
    MoviesWithActors mw
ORDER BY 
    mw.total_cast_count DESC;

SELECT 
    t.title, 
    t.production_year,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year < 2010
    AND (t.title ILIKE '%Love%' OR ak.name IS NULL)
GROUP BY 
    t.title, t.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 10
ORDER BY 
    keyword_count DESC, t.production_year ASC;

SELECT 
    ci.movie_id,
    COUNT(*) AS total_movies,
    AVG(m.production_year) AS avg_year
FROM 
    cast_info ci
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    mi.info IS NOT NULL
GROUP BY 
    ci.movie_id
HAVING 
    AVG(m.production_year) < 2005
ORDER BY 
    total_movies DESC;
