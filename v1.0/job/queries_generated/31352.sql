WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select all movies directly associated with companies
    SELECT
        mc.movie_id,
        c.name AS company_name,
        1 AS level
    FROM
        movie_companies mc
    JOIN
        company_name c ON mc.company_id = c.id
    WHERE
        mc.company_type_id IS NOT NULL

    UNION ALL

    -- Recursive case: Link each movie to its parent movie if it exists
    SELECT
        ml.linked_movie_id AS movie_id,
        mh.company_name,
        level + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
)

SELECT
    t.title,
    t.production_year,
    ak.name AS actor_name,
    COUNT(DISTINCT mh.company_name) AS companies_count,
    AVG(CAST(SUBSTRING(info.info FROM '%\"%\"')) AS FLOAT) AS avg_rating,
    ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mh.company_name) DESC) AS rank,
    CASE
        WHEN COUNT(DISTINCT mh.company_name) > 5 THEN 'High Production'
        ELSE 'Low Production'
    END AS production_quality
FROM
    title t
LEFT JOIN
    cast_info ci ON t.id = ci.movie_id
LEFT JOIN
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN
    MovieHierarchy mh ON t.id = mh.movie_id
LEFT JOIN
    movie_info info ON t.id = info.movie_id AND info.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE
    t.production_year > 2000
    AND t.title NOT LIKE '%Remake%'
GROUP BY
    t.id, ak.name, t.production_year
HAVING
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY
    production_quality, t.production_year DESC;
