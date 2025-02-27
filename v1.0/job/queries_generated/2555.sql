WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE m.production_year IS NOT NULL
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.actor_count_rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM TopMovies tm
    LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.actor_names, 'No actors') AS actor_names,
    COALESCE(md.keyword_count, 0) AS keyword_count
FROM MovieDetails md
WHERE md.keyword_count > 0
ORDER BY md.production_year DESC, md.title ASC;
