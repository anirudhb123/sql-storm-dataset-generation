WITH RECURSIVE movie_graph AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL AND mt.production_year > 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mg.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_graph mg ON ml.movie_id = mg.movie_id
    WHERE
        mg.level < 3  -- limit depth of the recursion
)

SELECT 
    k.keyword,
    COUNT(DISTINCT c.person_id) AS actor_count,
    AVG(CASE 
            WHEN ci.nr_order IS NOT NULL THEN ci.nr_order 
            ELSE 0 
        END) AS avg_order,
    MAX(mg.production_year) AS latest_year
FROM 
    keyword k
LEFT JOIN 
    movie_keyword mk ON k.id = mk.keyword_id
LEFT JOIN 
    aka_title at ON mk.movie_id = at.id
LEFT JOIN 
    cast_info ci ON at.id = ci.movie_id
LEFT JOIN 
    complete_cast cc ON at.id = cc.movie_id
LEFT JOIN 
    movie_graph mg ON at.id = mg.movie_id
WHERE 
    (k.keyword IS NOT NULL AND k.keyword NOT LIKE '%action%')
    OR (mg.production_year IS NULL AND EXISTS(
        SELECT 1
        FROM title t
        WHERE t.id = at.id AND t.production_year < 2005
    ))
GROUP BY 
    k.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) >= 5
ORDER BY 
    avg_order DESC,
    actor_count DESC
FETCH FIRST 10 ROWS ONLY;

-- Additional metrics
SELECT 
    mg.title,
    STRING_AGG(DISTINCT co.name, ', ') AS companies,
    COUNT(DISTINCT ci.person_id) AS cast_size
FROM 
    movie_graph mg
LEFT JOIN 
    movie_companies mc ON mg.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    cast_info ci ON mg.movie_id = ci.movie_id
GROUP BY 
    mg.title
HAVING 
    COUNT(ci.person_id) > 3
ORDER BY 
    cast_size DESC
LIMIT 5;

-- Final finishing touch to showcase NULL handling
SELECT 
    mt.title,
    COALESCE(AVG(ci.nr_order), 0) AS average_order,
    COUNT(ci.id) FILTER (WHERE ci.note IS NOT NULL) AS noted_actors
FROM 
    aka_title mt 
LEFT JOIN 
    cast_info ci ON mt.id = ci.movie_id
WHERE 
    mt.production_year = (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL)
GROUP BY 
    mt.title;

This SQL query incorporates various complex structures such as CTEs, JOINs, aggregate functions, conditional logic, filtering, and the handling of NULL values. The recursive CTE generates a movie graph with multiple layers of linked movies, while various JOINs link to actor, company, and keyword data. The use of advanced predicates and conditional aggregations makes the query both intricate and illustrative of SQL's expressive capabilities. The final segments highlight the importance of NOT NULL in joins and aggregates, showcasing the robustness and flexibility of SQL in handling complex data relationships and edge cases.
