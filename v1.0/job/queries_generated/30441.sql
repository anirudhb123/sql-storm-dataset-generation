WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM
        aka_title AS m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM
        movie_link AS ml
    JOIN movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
    JOIN aka_title AS m ON ml.linked_movie_id = m.id
    WHERE
        mh.depth < 5  -- Limit recursion depth for performance
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    c.name AS company_name,
    COUNT(DISTINCT ca.id) AS num_cast,
    COALESCE(ROUND(AVG(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) * 100, 2), 0) AS female_percentage,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ca.id) DESC) AS rank_by_cast_count
FROM 
    movie_hierarchy AS m
LEFT JOIN 
    complete_cast AS cc ON m.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ca ON cc.subject_id = ca.person_id
LEFT JOIN 
    movie_companies AS mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_name AS c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
LEFT JOIN 
    person_info AS p ON ca.person_id = p.person_id
WHERE 
    (m.production_year IS NOT NULL)
    AND (c.country_code IS NULL OR c.country_code IN ('USA', 'CANADA'))
GROUP BY 
    m.title, m.production_year, c.name
HAVING 
    COUNT(DISTINCT ca.id) > 3
ORDER BY 
    m.production_year DESC, num_cast DESC;


This query does the following:

1. Defines a recursive CTE to gather movies and their linked movies up to a depth of 5.
2. Selects distinct movie titles and their production years, along with the companies associated with them.
3. Counts the number of distinct cast members and calculates the percentage representation of female cast members.
4. Gathers associated keywords for each movie.
5. Uses window functions to rank movies by the number of cast members per production year.
6. Filters for movies that have companies from specified countries and a minimum count of cast members.
7. Orders the final results by production year and the count of cast members.
