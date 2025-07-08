
WITH RankedMovies AS (
    SELECT 
        a.id AS aka_title_id,
        a.title AS movie_title,
        t.id AS title_id,
        t.production_year,
        COUNT(ci.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') AS actor_names
    FROM aka_title a
    JOIN title t ON a.movie_id = t.id
    LEFT JOIN cast_info ci ON t.id = ci.movie_id
    LEFT JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY a.id, t.id, a.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_count,
        actor_names,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rnk
    FROM RankedMovies
)
SELECT 
    movie_title, 
    production_year, 
    actor_count, 
    actor_names
FROM TopMovies
WHERE rnk <= 5
ORDER BY production_year DESC, actor_count DESC;
