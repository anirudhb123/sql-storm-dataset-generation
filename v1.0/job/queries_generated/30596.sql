WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Filter for movies only

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        mtt.title,
        mtt.production_year,
        mh.level + 1 AS level
    FROM
        movie_link ml
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN
        aka_title mtt ON ml.linked_movie_id = mtt.id
)

SELECT
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    p.info AS actor_info,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY at.production_year DESC) AS rank,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    aka_title at ON ci.movie_id = at.id
LEFT JOIN
    movie_companies mc ON mc.movie_id = at.id
LEFT JOIN
    person_info p ON p.person_id = ak.person_id AND p.info_type_id IS NULL
WHERE
    ak.name IS NOT NULL
    AND at.production_year BETWEEN 2000 AND 2023
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    AND NOT EXISTS (
        SELECT 1
        FROM movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        WHERE mk.movie_id = at.id AND k.keyword = 'flop'
    )
GROUP BY
    ak.name, at.title, at.production_year, p.info
ORDER BY
    actor_name, rank, at.production_year DESC;

This query performs the following:
1. A recursive CTE `MovieHierarchy` which constructs a hierarchy of movies linked together in a self-referential manner.
2. A main select statement that retrieves actors' names, their movie titles, production years, associated information, and ranks based on most recent production.
3. It aggregates the count of production companies associated with each movie.
4. It incorporates filters for movie types and ensures that no movie labeled 'flop' exists based on keywords.
5. The use of window functions (`ROW_NUMBER`) to assign ranks to movies per actor while maintaining the order of production years.
6. Several joins to gather data from relevant tables while managing NULL logic appropriately.
