WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title AS mt
    WHERE
        mt.production_year >= 2000 -- Select movies from 2000 onwards
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        MovieHierarchy AS mh
    JOIN
        movie_link AS ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title AS at ON ml.linked_movie_id = at.id
)
SELECT
    m.title AS Movie_Title,
    m.production_year,
    COUNT(DISTINCT ci.person_id) AS Total_Cast,
    AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS Avg_Has_Role,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    COUNT(DISTINCT mk.keyword) AS Total_Keywords,
    SUM(mi.info IS NOT NULL) AS Total_Info_Entries
FROM
    MovieHierarchy AS m
LEFT JOIN
    cast_info AS ci ON m.movie_id = ci.movie_id
LEFT JOIN
    aka_name AS ak ON ci.person_id = ak.person_id
LEFT JOIN
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN
    movie_info AS mi ON m.movie_id = mi.movie_id
WHERE
    m.level <= 3 -- Focus on the movie hierarchy up to level 3
GROUP BY
    m.movie_id, m.title, m.production_year
ORDER BY
    Total_Cast DESC,
    m.production_year DESC
LIMIT 10;

This SQL query:

- Uses a recursive common table expression (CTE) to create a hierarchy of movies linked to each other via the `movie_link` table, specifically focusing on movies produced after the year 2000.
- Joins multiple tables to gather information about the cast, such as total cast members, average roles assigned to cast members, and their names.
- Counts the total number of keywords associated with each movie and the number of additional information entries linked to the movie.
- Filters the hierarchy to a defined level (in this case, level 3) to limit the results and provides a count of cast members as well as aggregates names into a single string.
- Orders the results first by the number of cast members and then by production year, limiting the output to the top 10 results.
