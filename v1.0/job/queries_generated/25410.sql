WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.id) DESC) AS movie_rank
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT
        rm.movie_id,
        rm.movie_title,
        rm.production_year
    FROM RankedMovies rm
    WHERE rm.movie_rank <= 5
),
MovieDetails AS (
    SELECT
        tm.movie_title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM TopMovies tm
    LEFT JOIN aka_title at ON at.movie_id = tm.movie_id
    LEFT JOIN aka_name ak ON ak.id = at.id
    LEFT JOIN movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY tm.movie_title, tm.production_year
)
SELECT
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.companies,
    md.keywords
FROM MovieDetails md
ORDER BY md.production_year DESC;
