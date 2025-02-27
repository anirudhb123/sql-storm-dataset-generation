WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.title,
    mh.production_year,
    mh.keyword,
    p.name AS director_name,
    COUNT(ci.id) AS cast_count,
    AVG(CASE 
            WHEN p.gender = 'M' THEN 1 
            ELSE 0 
        END) AS male_director_percentage,
    SUM(CASE 
            WHEN ci.note IS NULL THEN 1 
            ELSE 0 
        END) AS unchecked_cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name p ON ci.person_id = p.person_id
WHERE 
    mh.level = 1  -- Top level movies only
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, p.name
HAVING 
    COUNT(ci.id) > 5  -- Movies with more than 5 cast members
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC
LIMIT 10;

-- String manipulation example for movie titles
SELECT 
    DISTINCT REPLACE(mh.title, 'The', '') AS cleaned_title
FROM 
    MovieHierarchy mh
WHERE 
    mh.keyword <> 'No Keywords' 
    AND mh.level = 1;

This SQL query involves a recursive common table expression (CTE) to build a hierarchy of movies, filters movies produced after 2000, and then joins that with various tables to gather information about directors, cast count, and percentages of male directors. It employs window functions and includes NULL logic in calculations. The second part demonstrates string manipulation by removing the word "The" from movie titles, providing insight into potential data cleanup.
