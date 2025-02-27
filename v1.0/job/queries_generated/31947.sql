WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id, 
        title.title, 
        title.production_year,
        1 AS level
    FROM 
        title
    WHERE 
        title.season_nr IS NULL  -- Start from movies (not episodes)
    
    UNION ALL

    SELECT 
        aka_title.id AS movie_id, 
        aka_title.title, 
        aka_title.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        aka_title ON aka_title.episode_of_id = mh.movie_id
)
SELECT 
    t.title AS MovieTitle, 
    t.production_year AS ProductionYear, 
    COUNT(ci.id) AS CastCount,
    AVG(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS AverageRoleOrder,
    STRING_AGG(DISTINCT c.name, ', ') AS CastNames,
    MAX(mk.keyword) AS MostCommonKeyword,
    COALESCE(COUNT(DISTINCT mc.company_id), 0) AS ProductionCompanies
FROM 
    MovieHierarchy t
LEFT JOIN 
    cast_info ci ON ci.movie_id = t.movie_id
LEFT JOIN 
    aka_title at ON at.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
LEFT JOIN 
    aka_name c ON c.person_id = ci.person_id
WHERE 
    t.production_year >= (SELECT AVG(production_year) FROM title WHERE production_year IS NOT NULL)
GROUP BY 
    t.movie_id, t.title, t.production_year
HAVING 
    COUNT(ci.id) > 3 
ORDER BY 
    t.production_year DESC
LIMIT 10;

This SQL query performs the following tasks:
1. **Recursive Common Table Expression (CTE)**: The `MovieHierarchy` CTE is used to create a hierarchy of movies and their corresponding episodes.
2. **Joins**: It uses several left joins to gather data from relevant tables regarding cast info, movie keywords, and production companies.
3. **Aggregations**: It calculates the count of cast members, average order of roles, the most common keyword associated with the movie, and the number of production companies involved.
4. **Filters**: The `WHERE` clause filters movies released after the average production year, while the `HAVING` clause ensures only movies with more than three cast members are included.
5. **String Aggregation**: `STRING_AGG` is utilized to concatenate cast member names into a single string.
6. **Ordering and Limitation**: Finally, results are sorted by production year in descending order and limited to the top 10 entries.
