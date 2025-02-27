WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Starting from the year 2000
    UNION ALL
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN movie_link ml ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON m.id = ml.linked_movie_id
)
SELECT
    mv.title AS Movie_Title,
    mv.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN p.gender = 'M' THEN 1 ELSE 0 END) AS Male_Ratio,
    SUM(CASE WHEN p.gender IS NULL THEN 1 ELSE 0 END) AS Unknown_Gender,
    STRING_AGG(DISTINCT cn.name, ', ') AS Company_Names,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Rank_By_Cast_Size,
    CASE
        WHEN COUNT(DISTINCT ci.person_id) + 10 > 50 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ci.person_id) BETWEEN 20 AND 50 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS Cast_Size_Classification
FROM
    MovieHierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    person_info p ON p.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mv.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE
    mv.depth < 3 -- Limit to a maximum hierarchy depth of 2
GROUP BY
    mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 -- Only include movies with more than 5 cast members
ORDER BY 
    mv.production_year DESC, Total_Cast DESC;
