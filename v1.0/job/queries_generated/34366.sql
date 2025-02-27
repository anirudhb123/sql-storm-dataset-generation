WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NULL -- Only consider movies without additional notes

    UNION ALL

    SELECT 
        mh.movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    STRING_AGG(DISTINCT p.info, ', ') AS production_companies,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num,
    (SELECT AVG(info_type_id) 
     FROM movie_info 
     WHERE movie_id = mh.movie_id) AS avg_info_type_id
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name p ON mc.company_id = p.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 5 -- Only consider movies with more than 5 cast members
    AND mh.production_year > 2000 -- Only movies released after the year 2000
ORDER BY 
    mh.production_year DESC,
    mh.title;

-- Optionally, we can include outer joins or other constructs to enhance the query further,
-- However, this query captures complex relationships and combines multiple tables.
