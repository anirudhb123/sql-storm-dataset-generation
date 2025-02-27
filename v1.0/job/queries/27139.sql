
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS actor_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actors
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        company_name ON movie_companies.company_id = company_name.id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id, title.title, title.production_year
),

HighActorMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        actors
    FROM 
        RankedMovies
    WHERE 
        actor_count > 10
),

MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
)

SELECT 
    ham.movie_id,
    ham.title,
    ham.production_year,
    ham.actor_count,
    ham.actors,
    mk.keywords
FROM 
    HighActorMovies ham
LEFT JOIN 
    MovieKeywords mk ON ham.movie_id = mk.movie_id
ORDER BY 
    ham.production_year DESC, 
    ham.actor_count DESC;
