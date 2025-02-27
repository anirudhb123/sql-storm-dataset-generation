WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM title AS t
    JOIN aka_title AS at ON t.id = at.movie_id
    JOIN cast_info AS c ON t.id = c.movie_id
    JOIN aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY t.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        actor_count,
        actors_list,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY actor_count DESC, keyword_count DESC) AS rk
    FROM RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    k.kind AS movie_kind,
    tm.actor_count,
    tm.actors_list,
    tm.keyword_count
FROM TopMovies AS tm
JOIN kind_type AS k ON tm.kind_id = k.id
WHERE tm.rk <= 10
ORDER BY tm.actor_count DESC, tm.keyword_count DESC;
