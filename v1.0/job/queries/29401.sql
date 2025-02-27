
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title a
    JOIN movie_keyword mk ON a.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year >= 2000
    GROUP BY a.title, a.production_year, a.id
    HAVING COUNT(DISTINCT c.person_id) > 5
),

TopRatedMovies AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        m.keywords,
        m.actor_count,
        ROW_NUMBER() OVER (ORDER BY m.actor_count DESC) AS rank
    FROM RankedMovies m
    WHERE m.actor_count > 10
),

MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT n.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT co.name, ', ') AS production_companies,
        tm.keywords
    FROM TopRatedMovies tm
    JOIN complete_cast cc ON tm.movie_id = cc.movie_id
    JOIN name n ON cc.subject_id = n.imdb_id
    JOIN movie_companies mc ON tm.movie_id = mc.movie_id
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY tm.movie_id, tm.title, tm.production_year, tm.keywords
)

SELECT 
    d.title,
    d.production_year,
    d.cast_names,
    d.production_companies,
    d.keywords
FROM MovieDetails d
WHERE d.production_year > 2010
ORDER BY d.production_year DESC, d.title;
