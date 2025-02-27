WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        0 AS level,
        mt.id AS movie_id,
        ARRAY[mt.id] AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mh.level + 1,
        mt.id AS movie_id,
        mh.path || mt.id
    FROM 
        aka_title mt
    INNER JOIN 
        movie_link ml ON mt.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_title,
    mh.production_year,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN mt.production_year IS NOT NULL THEN mt.production_year END) AS linked_movie_year,
    ARRAY_AGG(DISTINCT c.name) FILTER (WHERE c.country_code IS NOT NULL) AS production_companies,
    MAX(CASE WHEN inf.info IS NOT NULL THEN inf.info END) AS additional_info,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_info inf ON mh.movie_id = inf.movie_id AND inf.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    mh.level < 5
GROUP BY 
    mh.movie_title, 
    mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    mh.production_year DESC, 
    actor_count DESC;

-- To analyze NULL handling, query distinct titles with various highly specific criteria:
SELECT 
    mt.title,
    CASE 
        WHEN mk.keyword IS NOT NULL THEN mk.keyword 
        ELSE 'No Keyword' 
    END AS keyword_info,
    COALESCE(cm.name, 'Independent') AS company_name,
    t.kind AS title_kind
FROM 
    aka_title mt
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
JOIN 
    kind_type t ON mt.kind_id = t.id
WHERE 
    mt.production_year BETWEEN 1990 AND 2020
    AND (mt.title LIKE '%Action%' OR mk.keyword IS NOT NULL)
ORDER BY 
    keyword_info COLLATE "C" -- Using a specific collation for sorting
FETCH FIRST 100 ROWS ONLY;

-- Combining results that entail set operations:
WITH GenreCounts AS (
    SELECT 
        mt.kind_id,
        COUNT(DISTINCT mt.id) AS movie_count
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.kind_id
) 

SELECT 
    gt.kind,
    COALESCE(gc.movie_count, 0) AS total_movies
FROM 
    kind_type gt
LEFT JOIN 
    GenreCounts gc ON gt.id = gc.kind_id
WHERE 
    gt.kind LIKE '%Drama%'
UNION 
SELECT 
    'TOTAL' AS kind,
    COUNT(DISTINCT mt.id) 
FROM 
    aka_title mt
WHERE 
    mt.production_year IS NOT NULL;

-- Final unique combination of structured data with various NULL handling scenarios:
SELECT 
    DISTINCT t.title AS title,
    ak.name AS actor_name,
    p.info AS person_info,
    COALESCE(mk.keyword, 'No Keywords') AS movie_keyword
FROM 
    aka_title t
LEFT JOIN 
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.title IS NOT NULL 
    AND ak.name IS NOT NULL 
    AND p.info IS NULL
ORDER BY 
    t.title;

