WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
),
MovieDetails AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actor_list,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        movie_keyword mk ON mk.movie_id = rm.id
    GROUP BY 
        rm.movie_title, rm.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_list,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC) AS rank_by_keywords
    FROM 
        MovieDetails
)
SELECT 
    movie_title,
    production_year,
    actor_list,
    keyword_count
FROM 
    TopMovies
WHERE 
    rank_by_keywords <= 10
ORDER BY 
    production_year DESC, movie_title;
