WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

KeywordedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.cast_names,
        COALESCE(STRING_AGG(DISTINCT k.keyword, ', '), 'No Keywords') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.cast_count, rm.cast_names
),

FinalActorsMovies AS (
    SELECT 
        km.movie_id,
        km.title,
        km.production_year,
        km.cast_count,
        km.cast_names,
        km.keywords,
        COALESCE(ACTOR_ROLES.role_names, 'No Roles') AS actor_roles
    FROM 
        KeywordedMovies km
    LEFT JOIN (
        SELECT 
            c.movie_id,
            STRING_AGG(DISTINCT rt.role, ', ') AS role_names
        FROM 
            cast_info c
        JOIN 
            role_type rt ON c.role_id = rt.id
        GROUP BY 
            c.movie_id
    ) ACTOR_ROLES ON km.movie_id = ACTOR_ROLES.movie_id
)

SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    cast_names,
    keywords,
    actor_roles
FROM 
    FinalActorsMovies
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 50;
