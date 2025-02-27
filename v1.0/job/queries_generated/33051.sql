WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)

SELECT 
    mk.keyword,
    COUNT(DISTINCT c.person_id) AS total_cast,
    AVG(mh.level) AS avg_level,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    movie_keyword mk
JOIN 
    aka_title at ON mk.movie_id = at.id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    cast_info c ON at.id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
    AND at.production_year >= 2000
    AND (ak.name IS NOT NULL AND ak.name <> '')
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT c.person_id) > 5
ORDER BY 
    total_cast DESC, 
    avg_level ASC;
This SQL query does the following:

1. Uses a recursive common table expression (`RECURSIVE movie_hierarchy`) to build a hierarchy of movies linked to each other.
2. Joins various tables to gather additional information about movies, keywords, cast members, and companies.
3. Uses aggregate functions (`COUNT`, `AVG`, and `STRING_AGG`) to return a list of keywords, the total number of distinct cast members for each keyword, the average level of the movie's hierarchy, and a comma-separated list of actor names.
4. Filters results for movies produced after the year 2000 and associated with USA-based companies.
5. Utilizes a `HAVING` clause to only include keywords that have more than five distinct cast members.
6. Orders the final results by the total cast in descending order and the average level in ascending order.
