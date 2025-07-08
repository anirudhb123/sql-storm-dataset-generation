
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),

ActorRoles AS (
    SELECT 
        ci.movie_id,
        co.name AS company_name,
        r.role AS role_name,
        COUNT(*) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        company_name co ON ci.movie_id = (SELECT id FROM movie_companies WHERE movie_id = ci.movie_id LIMIT 1)
    GROUP BY 
        ci.movie_id, co.name, r.role
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.company_name,
        ar.role_name,
        ar.actor_count,
        rm.keyword
    FROM 
        RankedMovies rm
    JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.rank = 1
)

SELECT 
    title,
    production_year,
    company_name,
    role_name,
    actor_count,
    LISTAGG(keyword, ', ') WITHIN GROUP (ORDER BY keyword) AS keywords
FROM 
    MovieDetails
GROUP BY 
    title, 
    production_year, 
    company_name, 
    role_name, 
    actor_count
ORDER BY 
    production_year DESC, 
    title ASC;
