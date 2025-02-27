WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS total_order,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title AS c ON ci.movie_id = c.id
    GROUP BY 
        ak.id, ak.name
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ai.actor_name,
    ai.movie_count,
    ai.total_order,
    (SELECT COUNT(*) FROM cast_info ci2 WHERE ci2.movie_id = rm.id AND ci2.note IS NOT NULL) AS note_count
FROM 
    ranked_movies AS rm
LEFT OUTER JOIN 
    actor_info AS ai ON rm.cast_count > ai.movie_count
WHERE 
    rm.rank <= 5 AND (rm.production_year IS NOT NULL OR ai.movie_count > 5)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC, ai.actor_rank ASC

UNION ALL 

SELECT 
    'Total Actors' AS title,
    NULL AS production_year,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    NULL,
    NULL,
    NULL,
    NULL
FROM 
    cast_info AS ci
WHERE 
    ci.note IS NOT NULL 
    OR EXISTS (SELECT 1 FROM aka_name ak WHERE ci.person_id = ak.person_id AND ak.md5sum IS NOT NULL)

ORDER BY 
    production_year DESC NULLS LAST, cast_count DESC;

In this SQL query:

- We use CTEs to create `ranked_movies` which ranks movies based on the count of distinct cast members per production year.
- The second CTE, `actor_info`, summarizes actor information, including their movie counts and the total of their `nr_order`, alongside ranking them.
- An outer join is performed to combine the results of `ranked_movies` and `actor_info` under certain conditions, including handling NULL values for predicates.
- A `UNION ALL` includes a summary row counting total actors, filtering based on note presence and MD5 checksum of the actors' names.
- `ORDER BY` includes oddities like `NULLS LAST`, ensuring the right display order when some values may be NULL.

This query blends various SQL features for comprehensive performance benchmarking.
