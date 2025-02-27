WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM
        movie_link ml
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT
    ak.name AS actor_name,
    ak.id AS actor_id,
    mh.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mki.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) FILTER (WHERE ct.kind = 'Distributor') AS distributor_count,
    COALESCE(SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS personal_info_count,
    SUM(CASE 
        WHEN mh.level >= 2 THEN 1 
        ELSE 0 
    END) AS sequel_count
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN
    company_type ct ON mc.company_type_id = ct.id
JOIN
    movie_keyword mki ON ci.movie_id = mki.movie_id
JOIN
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN
    person_info pi ON ak.person_id = pi.person_id
WHERE
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%unknown%'
    AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY
    ak.name,
    ak.id,
    mh.title,
    mh.production_year
HAVING
    COUNT(DISTINCT mki.keyword) FILTER (WHERE mki.keyword != '') > 0
ORDER BY
    keyword_count DESC,
    mh.title ASC,
    ak.name ASC
LIMIT 100;

In this query:
1. A Common Table Expression (CTE) named `movie_hierarchy` is generated to create a recursive view of movies linked together by the `movie_link` table.
2. Multiple joins allow for the fetching of actors' names, movie titles, companies involved, and related keywords.
3. The use of `FILTER` clauses allows for conditional aggregation.
4. It counts various things: number of distinct keywords per actor-movie combination, number of distributor companies, and encapsulates quirky counts based on certain criteria like production years.
5. The query incorporates various filtering conditions ensuring the robustness of results (null checks, exclusions of particular names).
6. The `HAVING` clause ensures that results only include those with actual keywords.
7. Results are ordered by keyword count, movie title, and actor name, providing a clear view of the relationships.
