WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 

CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(n.name, ', ') AS actor_names
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
), 

CompanyDetails AS (
    SELECT 
        m.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
)

SELECT 
    r.title,
    r.production_year,
    cd.actor_count,
    cd.actor_names,
    COALESCE(comp.company_name, 'No Company') AS company_name,
    comp.company_type
FROM 
    RankedMovies r
LEFT JOIN 
    CastDetails cd ON r.id = cd.movie_id
LEFT JOIN 
    CompanyDetails comp ON r.id = comp.movie_id
WHERE 
    r.year_rank <= 5 -- Top 5 movies per year
ORDER BY 
    r.production_year DESC, 
    cd.actor_count DESC;
