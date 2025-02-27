WITH TopMovies AS (
    SELECT title.id AS movie_id, title.title, title.production_year, COUNT(movie_keyword.keyword_id) AS keyword_count
    FROM title
    JOIN movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY title.id, title.title, title.production_year
    ORDER BY keyword_count DESC
    LIMIT 10
),
CastDetails AS (
    SELECT cast_info.movie_id, aka_name.name AS actor_name, role_type.role
    FROM cast_info
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    JOIN role_type ON cast_info.role_id = role_type.id
)
SELECT tm.title, tm.production_year, cd.actor_name, cd.role
FROM TopMovies tm
JOIN CastDetails cd ON tm.movie_id = cd.movie_id
ORDER BY tm.production_year DESC, cd.actor_name;
