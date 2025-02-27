WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        ac.name AS actor_name,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ac.person_id) DESC) AS actor_rank
    FROM aka_title AS a
    JOIN movie_keyword AS mk ON a.id = mk.movie_id
    JOIN keyword AS k ON mk.keyword_id = k.id
    JOIN cast_info AS ci ON a.id = ci.movie_id
    JOIN aka_name AS ac ON ci.person_id = ac.person_id
    JOIN title AS t ON a.id = t.id
    WHERE t.production_year IS NOT NULL
    GROUP BY a.title, ac.name, t.production_year, k.keyword
),
TopActors AS (
    SELECT
        movie_title,
        actor_name,
        production_year,
        movie_keyword,
        actor_rank
    FROM RankedMovies
    WHERE actor_rank <= 3  -- Take top 3 actors for each production year
)
SELECT 
    production_year,
    STRING_AGG(actor_name, ', ') AS top_actors,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS associated_keywords,
    COUNT(DISTINCT movie_title) AS total_movies
FROM TopActors
GROUP BY production_year
ORDER BY production_year;

