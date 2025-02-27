WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
PopularActors AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
MovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ra.name AS main_actor,
        ra.movie_count AS actor_movies,
        r.keyword
    FROM 
        RankedMovies r
    LEFT JOIN 
        PopularActors ra ON r.movie_id = ci.movie_id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    WHERE 
        r.year_rank <= 3
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.main_actor, 'No main actor') AS main_actor,
    COALESCE(md.actor_movies, 0) AS actor_movies,
    md.keyword 
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movie_id ASC;
