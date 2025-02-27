WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ko.keyword,
    COUNT(DISTINCT cc.id) AS cast_count,
    COALESCE(AVG(CASE WHEN p.gender = 'M' THEN 1 END), 0) AS avg_male_actors,
    MAX(mh.production_year) AS latest_year
FROM 
    keyword ko
JOIN 
    movie_keyword mk ON ko.id = mk.keyword_id
JOIN 
    aka_title at ON mk.movie_id = at.id
JOIN 
    complete_cast cc ON at.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    person_info pi ON ci.person_id = pi.person_id
LEFT JOIN 
    name p ON cc.subject_id = p.imdb_id
LEFT JOIN
    MovieHierarchy mh ON at.id = mh.movie_id
WHERE 
    ko.keyword IS NOT NULL
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    ko.keyword
ORDER BY 
    cast_count DESC
LIMIT 10;

