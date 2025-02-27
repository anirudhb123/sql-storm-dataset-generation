WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM
        aka_title m
    WHERE
        m.production_year >= 2000
  
    UNION ALL
  
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        h.level + 1
    FROM
        movie_link ml
    JOIN
        movie_hierarchy h ON ml.movie_id = h.movie_id
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    WHERE
        h.level < 5
),
ranked_cast AS (
    SELECT
        c.movie_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
),
movie_keyword_summary AS (
    SELECT
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)
SELECT
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT rc.actor_rank) AS actor_count,
    COALESCE(mks.keywords, 'No Keywords') AS keywords_summary,
    mh.level
FROM
    movie_hierarchy mh
LEFT JOIN
    ranked_cast rc ON mh.movie_id = rc.movie_id
LEFT JOIN
    movie_keyword_summary mks ON mh.movie_id = mks.movie_id
WHERE
    mh.production_year IS NOT NULL
GROUP BY
    mh.movie_id, mh.title, mh.production_year, mks.keywords, mh.level
HAVING
    COUNT(DISTINCT rc.actor_rank) > 2
ORDER BY
    mh.production_year DESC, mh.title ASC;

This SQL query performs the following actions:
1. It maintains a recursive CTE to find movies produced from the year 2000 onwards and any linked movies up to 5 levels deep.
2. It ranks actors in each movie by their order in the cast using a window function.
3. It aggregates keywords associated with each movie into a single string using `STRING_AGG`.
4. The main query then collects all these results while ensuring that only movies with a count of more than 2 distinct actors are selected.
5. Finally, it orders the results by production year and title.
