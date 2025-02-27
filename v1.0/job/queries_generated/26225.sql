WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id, 
        title.title AS movie_title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS rank_in_year
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT
        c.movie_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id, a.name
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.rank_in_year,
    mk.keywords,
    ar.actor_name,
    ar.roles
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
WHERE 
    rm.rank_in_year <= 5 -- Let's limit to the top 5 movies per year
ORDER BY 
    rm.production_year DESC, rm.rank_in_year;

