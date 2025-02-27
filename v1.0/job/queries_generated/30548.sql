WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        1 AS level,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        aka_title m
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    WHERE
        m.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mh.level + 1,
        mt.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
)
SELECT 
    mv.title AS movie_title,
    mv.production_year,
    mv.keyword,
    COALESCE(ci.role, 'No Role') AS role,
    COUNT(DISTINCT c.id) AS total_cast_members,
    AVG(DATEDIFF(CURRENT_DATE, pi.birth_date)) AS average_age
FROM 
    movie_hierarchy mv
LEFT JOIN 
    cast_info ci ON mv.movie_id = ci.movie_id
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
LEFT JOIN 
    person_info pi ON an.person_id = pi.person_id
WHERE 
    pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birthdate')
GROUP BY 
    mv.movie_id, mv.title, mv.production_year, mv.keyword, ci.role
ORDER BY 
    mv.production_year DESC, total_cast_members DESC;

This SQL query does the following:
- It uses a recursive CTE (`movie_hierarchy`) to gather movie information along with linked movies while counting levels of the hierarchy based on relationships.
- The main query fetches movie details from the CTE and joins with various tables to get the role, average age of cast members, and handles NULL values with `COALESCE`.
- Aggregation is done to count distinct cast members and calculate average ages of actors with birthdates.
- It filters movies from 2000 onwards and orders the results by production year and the total cast members in descending order.
