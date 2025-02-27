WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        STRING_AGG(DISTINCT ka.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM
        title t
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN
        aka_name ka ON ci.person_id = ka.person_id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        movie_keyword,
        company_names
    FROM 
        RankedMovies
    WHERE 
        rank = 1 AND production_year >= 2000
)
SELECT
    movie_title,
    production_year,
    actor_names,
    movie_keyword,
    company_names,
    COUNT(*) OVER() AS total_movies
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, movie_title
LIMIT 10;
