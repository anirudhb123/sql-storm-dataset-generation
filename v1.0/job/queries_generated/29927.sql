WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        COUNT(ci.person_id) AS actor_count
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year, k.keyword
),
PopularMovies AS (
    SELECT 
        movie_title,
        production_year,
        movie_keyword,
        actor_count,
        RANK() OVER (PARTITION BY movie_keyword ORDER BY actor_count DESC) AS rank_within_keyword
    FROM 
        RankedMovies
)
SELECT 
    pm.movie_title,
    pm.production_year,
    pm.movie_keyword,
    pm.actor_count
FROM 
    PopularMovies pm
WHERE 
    pm.rank_within_keyword <= 5
ORDER BY 
    pm.movie_keyword, pm.actor_count DESC;
