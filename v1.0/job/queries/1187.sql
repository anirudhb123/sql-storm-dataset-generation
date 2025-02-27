
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank,
        COUNT(c.id) AS cast_count
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        tm.title_id,
        tm.title,
        tm.production_year,
        tm.cast_count
    FROM RankedMovies tm
    WHERE tm.movie_rank = 1
),
MovieDetails AS (
    SELECT 
        title.title,
        title.production_year,
        ak.name AS actor_name,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM TopMovies tm
    JOIN title ON tm.title_id = title.id
    LEFT JOIN cast_info ci ON title.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY title.title, title.production_year, ak.name
)
SELECT 
    md.title,
    md.production_year,
    md.actor_name,
    COALESCE(md.keywords, 'No keywords available') AS keywords
FROM MovieDetails md
WHERE md.production_year BETWEEN 1990 AND 2020
ORDER BY md.production_year DESC, md.title;
