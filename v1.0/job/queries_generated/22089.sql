WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RAND()) AS random_rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT
        ka.name AS actor_name,
        c.movie_id,
        c.nr_order,
        COALESCE(ka.md5sum, 'UNKNOWN') AS actor_md5
    FROM
        cast_info c
    JOIN aka_name ka ON c.person_id = ka.person_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(GROUP_CONCAT(DISTINCT a.actor_name) FILTER (WHERE a.actor_name IS NOT NULL), 'No Actors') AS actors,
        COALESCE(MAX(mi.info), 'No Info') AS additional_info,
        CASE 
            WHEN COUNT(DISTINCT a.actor_name) > 5 THEN 'Feature Film'
            ELSE 'Short Film'
        END AS film_type
    FROM
        aka_title m
    LEFT JOIN ActorInfo a ON m.id = a.movie_id
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    GROUP BY
        m.id, m.title
)
SELECT
    m.title,
    m.production_year,
    m.film_type,
    m.actors,
    RANK() OVER (ORDER BY m.production_year DESC) AS rank_by_year,
    COUNT(DISTINCT mk.keyword_id) AS keyword_count,
    STRING_AGG(DISTINCT ci.note, ', ') AS company_notes
FROM
    RankedMovies rm
JOIN MovieDetails m ON rm.movie_id = m.movie_id
LEFT JOIN movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN movie_info idx ON m.movie_id = idx.movie_id AND idx.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN movie_link ml ON m.movie_id = ml.movie_id
GROUP BY
    m.title, m.production_year, m.film_type, rm.random_rank
HAVING
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY
    m.production_year DESC, rank_by_year DESC
LIMIT 50 OFFSET 0;

This SQL query constructs a detailed analysis of movies, employing various advanced SQL features, including common table expressions (CTEs), window functions, outer joins, correlated subqueries, and GROUP BY with aggregation functions. It ranks movies based on their release years, categorizes them as either 'Feature Film' or 'Short Film' based on actor count, and includes keyword and company information while adding complexity with conditional logic and string functions.
