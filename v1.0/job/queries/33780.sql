
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id,
        ARRAY[mt.id] AS path
    FROM
        aka_title mt
    WHERE
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id,
        path || mt.id
    FROM
        aka_title mt
    JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
)
SELECT
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COALESCE(c.name, 'Unknown') AS Company_Name,
    COUNT(DISTINCT ci.person_id) AS Cast_Count,
    STRING_AGG(DISTINCT ak.name, ', ') AS Aliases,
    SUM(CASE WHEN ki.keyword IS NOT NULL THEN 1 ELSE 0 END) AS Keyword_Count,
    ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Rank_Per_Year
FROM
    MovieHierarchy m
LEFT JOIN
    complete_cast cc ON m.movie_id = cc.movie_id
LEFT JOIN
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN
    movie_companies mc ON mc.movie_id = m.movie_id
LEFT JOIN
    company_name c ON c.id = mc.company_id
LEFT JOIN
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN
    keyword ki ON ki.id = mk.keyword_id
WHERE
    (m.production_year > 2000 AND ci.note IS NULL)
    OR (m.production_year <= 2000 AND c.country_code IS NOT NULL)
GROUP BY
    m.movie_id, m.title, m.production_year, c.name
HAVING
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY
    Rank_Per_Year, m.production_year DESC;
