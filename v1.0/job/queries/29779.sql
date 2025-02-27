WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ka.name AS actor_name,
        ra.role AS actor_role,
        STRING_AGG(kw.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name ka ON c.person_id = ka.person_id
    JOIN 
        role_type ra ON c.role_id = ra.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
        AND ra.role LIKE '%actor%'
    GROUP BY 
        t.title, t.production_year, ka.name, ra.role
),
RankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_role,
        keywords,
        production_companies,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title) AS rank
    FROM 
        MovieDetails
)
SELECT 
    production_year,
    STRING_AGG(CONCAT(rank, ': ', movie_title, ' - ', actor_name, ' (', actor_role, ') - Keywords: ', keywords, ' - Companies: ', production_companies), '; ') AS movie_info
FROM 
    RankedMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
