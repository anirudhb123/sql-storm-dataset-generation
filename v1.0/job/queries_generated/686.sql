WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        r.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(CONCAT(actor_name, ' (', actor_role, ')'), ', ') AS actors
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
),
CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        m.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actors,
    cs.company_count,
    cs.companies_involved
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyStats cs ON md.movie_title = (
        SELECT 
            title 
        FROM 
            title 
        WHERE 
            id IN (
                SELECT movie_id 
                FROM complete_cast 
                WHERE subject_id = md.movie_title
            )
        LIMIT 1
    )
WHERE 
    cs.company_count > 0 OR cs.companies_involved IS NOT NULL
ORDER BY 
    md.production_year DESC, md.movie_title;
