WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank
    FROM 
        aka_title m 
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        STRING_AGG(movie_keyword, ', ') AS keywords
    FROM 
        RankedMovies
    WHERE 
        rank = 1
    GROUP BY 
        movie_id, title, production_year
),
ActorInfo AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, p.name
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.keywords,
        STRING_AGG(DISTINCT ai.actor_name || ' (' || ai.roles || ')', '; ') AS actors
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorInfo ai ON ci.person_id = ai.person_id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year, tm.keywords
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.keywords,
    md.actors
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title ASC;
