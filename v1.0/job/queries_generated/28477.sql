WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        COALESCE(mc.company_name, 'N/A') AS company_name,
        COALESCE(GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind), 'N/A') AS company_types
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, mc.company_name
),
RankedMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_name,
        keywords,
        company_name,
        company_types,
        ROW_NUMBER() OVER (ORDER BY production_year DESC) AS movie_rank
    FROM 
        MovieDetails
)

SELECT 
    movie_rank,
    title, 
    production_year, 
    actor_name, 
    keywords, 
    company_name, 
    company_types
FROM 
    RankedMovies
WHERE 
    movie_rank <= 10
ORDER BY 
    production_year DESC;
