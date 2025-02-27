WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        1 AS level
    FROM 
        title
    WHERE 
        production_year = 2020 -- Starting with movies from the year 2020

    UNION ALL

    SELECT 
        mt.linked_movie_id AS movie_id,
        t.title,
        t.production_year,
        mh.level + 1
    FROM 
        movie_link AS mt
    JOIN 
        title AS t ON mt.linked_movie_id = t.id
    JOIN 
        MovieHierarchy AS mh ON mt.movie_id = mh.movie_id
)

SELECT 
    m.title AS Movie_Title,
    m.production_year AS Production_Year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    AVG(CASE WHEN mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS DECIMAL) END) AS Average_Budget,
    COUNT(DISTINCT mk.keyword) AS Total_Keywords,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS Rank_By_Cast_Size
FROM 
    MovieHierarchy AS m
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info AS mi ON m.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0
ORDER BY 
    Production_Year DESC, Total_Cast DESC;

This SQL query achieves the following:
1. A recursive common table expression (`MovieHierarchy`) to retrieve a list of movies from 2020 and all movies linked to them.
2. It joins multiple tables to gather comprehensive data about each movie, including cast size, cast names, average budget, and keyword counts.
3. The `STRING_AGG` function is used to concatenate cast names into a single string.
4. It uses window functions to rank movies based on cast sizes for each year.
5. The `HAVING` clause ensures only movies with a non-zero cast count are returned.
6. The results are ordered first by production year (most recent first) and then by total cast size (largest first).
