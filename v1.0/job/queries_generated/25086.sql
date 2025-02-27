WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        k.keyword AS movie_keyword
    FROM title t
    JOIN aka_title at ON t.id = at.movie_id
    JOIN cast_info ci ON at.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type c ON ci.role_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year > 2000
      AND a.name IS NOT NULL
      AND a.name != ''
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords
    FROM MovieDetails
    GROUP BY movie_title, production_year
)
SELECT 
    production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(movie_title, '; ') AS movies,
    STRING_AGG(actors, '; ') AS all_actors,
    STRING_AGG(keywords, '; ') AS all_keywords
FROM AggregatedData
GROUP BY production_year
ORDER BY production_year DESC;
