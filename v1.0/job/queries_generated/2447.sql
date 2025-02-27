WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
),
CompanyData AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ci.company_count, 0) AS company_count,
        COALESCE(rm.actor_name, 'Unknown Actor') AS leading_actor
    FROM 
        aka_title m
    LEFT JOIN 
        CompanyData ci ON m.id = ci.movie_id
    LEFT JOIN 
        RankedMovies rm ON m.id = rm.movie_title AND rm.rank = 1
)
SELECT 
    md.title,
    md.production_year,
    md.company_count,
    md.leading_actor
FROM 
    MovieDetails md
WHERE 
    md.company_count > 1
    AND md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
