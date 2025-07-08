WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

ActorsInMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name,
        c.movie_id, 
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
),

MoviesWithActors AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year, 
        rm.companies, 
        rm.keywords, 
        ARRAY_AGG(DISTINCT a.actor_name) AS actors,
        COUNT(DISTINCT a.actor_id) AS actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorsInMovies a ON rm.movie_id = a.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.companies, rm.keywords
)

SELECT 
    mv.title,
    mv.production_year,
    mv.actors,
    mv.actor_count,
    mv.companies,
    mv.keywords
FROM 
    MoviesWithActors mv
WHERE 
    mv.actor_count > 5 
ORDER BY 
    mv.production_year DESC, mv.title ASC;
