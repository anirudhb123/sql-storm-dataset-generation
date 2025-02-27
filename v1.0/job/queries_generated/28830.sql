WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM title t
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name an ON ci.person_id = an.person_id
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank_within_year
    FROM RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    actor_names,
    keywords
FROM FilteredMovies
WHERE rank_within_year <= 5
ORDER BY production_year DESC, cast_count DESC;
