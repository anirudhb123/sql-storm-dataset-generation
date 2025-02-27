WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.year_rank <= 5
),
MovieDetails AS (
    SELECT 
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT p.info, ', ') AS actor_info
    FROM 
        TopMovies m
    LEFT JOIN 
        complete_cast cc ON m.title = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        m.title, m.production_year
),
CompanyDetails AS (
    SELECT 
        mt.title,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    GROUP BY 
        mt.title
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.actor_count,
    md.actor_info,
    cd.company_count,
    cd.companies
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails cd ON md.title = cd.title
WHERE 
    md.actor_count > 0 OR cd.company_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
