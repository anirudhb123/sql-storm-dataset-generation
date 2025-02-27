WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IS NOT NULL

    UNION ALL

    SELECT 
        cmt.id AS movie_id,
        cmt.title,
        cmt.production_year,
        cmt.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title cmt ON ml.linked_movie_id = cmt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name,
    ak.surname_pcode,
    COALESCE(COUNT(DISTINCT ci.role_id), 0) AS total_roles,
    COALESCE(SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS noted_roles,
    ARRAY_AGG(DISTINCT mt.title ORDER BY mt.production_year DESC) AS movie_titles,
    COUNT(DISTINCT CASE WHEN kw.keyword IS NOT NULL THEN kw.keyword END) AS unique_keywords
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND (ak.surname_pcode IS NULL OR ak.surname_pcode != 'XYZ')
    AND (mt.production_year > 2000 OR mt.kind_id NOT IN (SELECT id FROM kind_type WHERE kind = 'Documentary'))
GROUP BY 
    ak.id, ak.name, ak.surname_pcode
ORDER BY 
    total_roles DESC, ak.name ASC
LIMIT 10;

WITH title_count AS (
    SELECT 
        id,
        COUNT(movie_id) AS num_movies
    FROM 
        movie_companies
    GROUP BY 
        id
)
SELECT 
    c.name AS company_name,
    tc.num_movies,
    ARRAY_AGG(DISTINCT mt.title ORDER BY mt.production_year DESC) AS related_titles
FROM 
    company_name c
LEFT JOIN 
    movie_companies mc ON c.id = mc.company_id
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    title_count tc ON mc.id = tc.id
WHERE 
    c.country_code IS NOT NULL AND c.country_code != ''
GROUP BY 
    c.id, c.name, tc.num_movies
HAVING 
    COUNT(DISTINCT mt.id) > 5
ORDER BY 
    tc.num_movies DESC
LIMIT 20;

SELECT
    ak.name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_year_of_movies,
    STRING_AGG(DISTINCT mt.title, ', ') AS titles
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_info mi ON mt.id = mi.movie_id
WHERE 
    mi.info_type_id IS NULL
    OR (mt.production_year IS NOT NULL AND mt.production_year < 1990)
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT ci.role_id) > 1
ORDER BY 
    total_movies DESC
LIMIT 50;

SELECT 
    c.kind,
    COUNT(DISTINCT mc.movie_id) AS count_movies,
    SUM(CASE WHEN c.kind ILIKE '%Producing%' THEN 1 ELSE 0 END) AS producing_count,
    STRING_AGG(DISTINCT mt.title, ', ') AS titles
FROM 
    company_type c
LEFT JOIN 
    movie_companies mc ON c.id = mc.company_type_id
LEFT JOIN 
    aka_title mt ON mc.movie_id = mt.id
WHERE 
    c.kind IS NOT NULL
GROUP BY 
    c.id, c.kind
HAVING 
    COUNT(DISTINCT mc.movie_id) > 5
ORDER BY 
    count_movies DESC;
