WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title AS t
    JOIN 
        movie_companies AS mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA' 
        AND m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        mh.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy AS mh
    JOIN 
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title AS t ON ml.linked_movie_id = t.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(DISTINCT ca.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
    AVG(CASE 
        WHEN p.gender = 'F' THEN 1
        ELSE 0 
    END) OVER (PARTITION BY mh.movie_id) AS female_ratio
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    aka_name AS ak ON ca.person_id = ak.person_id
LEFT JOIN 
    name AS p ON ca.person_id = p.imdb_id
WHERE 
    mh.depth <= 3
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ca.person_id) > 5
ORDER BY 
    mh.production_year DESC, cast_count DESC;
