WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
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
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM
        MovieHierarchy mh
)
SELECT
    at.name AS actor_name,
    am.title AS movie_title,
    am.production_year,
    COALESCE(GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword), 'No keywords') AS keywords,
    COUNT(DISTINCT m.company_id) AS company_count,
    AVG(mi.info_length) AS avg_info_length,
    MAX(CASE WHEN pc.country_code IS NULL THEN 'Unknown' ELSE pc.country_code END) AS company_country
FROM
    cast_info ci
JOIN
    aka_name an ON ci.person_id = an.person_id
JOIN
    aka_title am ON ci.movie_id = am.id
LEFT JOIN
    movie_company m ON am.id = m.movie_id
LEFT JOIN
    company_name pc ON m.company_id = pc.id
LEFT JOIN
    movie_keyword mk ON am.id = mk.movie_id
LEFT JOIN
    keyword k ON mk.keyword_id = k.id
LEFT JOIN (
    SELECT
        movie_id,
        LENGTH(info) AS info_length
    FROM
        movie_info
) mi ON am.id = mi.movie_id
WHERE
    am.production_year BETWEEN 1990 AND 2023
GROUP BY
    an.name, am.title, am.production_year
HAVING
    COUNT(DISTINCT m.company_id) > 0
ORDER BY
    movie_title, production_year DESC;

This query does the following:
1. Constructs a recursive Common Table Expression (CTE) `MovieHierarchy` that builds a hierarchy of movies and their links, using `UNION ALL` to gather movies and their sequels or related movies.
2. A second CTE `RankedMovies` is created to rank these movies by production year, which can provide insights into how many linked movies exist per year and their respective depth in the hierarchy.
3. The main query retrieves actor names along with their respective movie titles and production years. It includes aggregate functions to count the number of companies involved with each movie, average the lengths of related info entries, and gather keywords associated with each title.
4. NULL handling is implemented to categorize companies without a known country as 'Unknown'.
5. The results are filtered to include only movies produced between 1990 and 2023, ensuring a focused timeframe for the performance benchmark while correctly grouping and ordering the output.
