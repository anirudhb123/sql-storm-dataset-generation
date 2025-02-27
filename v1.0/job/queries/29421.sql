WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
ActorMovieInfo AS (
    SELECT 
        c.movie_id,
        r.role AS actor_role,
        CONCAT(n.name, ' as ', r.role) AS actor_details
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        name n ON c.person_id = n.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.movie_keyword,
        am.actor_role,
        am.actor_details,
        cm.company_name,
        cm.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovieInfo am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        CompanyMovies cm ON rm.movie_id = cm.movie_id
)

SELECT 
    movie_title,
    production_year,
    movie_keyword,
    STRING_AGG(DISTINCT actor_details, '; ') AS actors,
    STRING_AGG(DISTINCT CONCAT(company_name, ' (', company_type, ')'), '; ') AS companies
FROM 
    MovieDetails
GROUP BY 
    movie_title, production_year, movie_keyword
ORDER BY 
    production_year DESC, movie_title;
