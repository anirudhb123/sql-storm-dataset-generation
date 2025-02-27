
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(t.production_year) OVER (PARTITION BY t.kind_id) AS max_year_per_type,
        STRING_AGG(DISTINCT ak.name, ', ') FILTER (WHERE ak.name IS NOT NULL) AS actors
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id 
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS total_companies,
        STRING_AGG(DISTINCT c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
), CombinedDetails AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        COALESCE(mc.total_companies, 0) AS total_companies,
        md.max_year_per_type,
        md.actors,
        mc.company_names
    FROM 
        MovieDetails md
    LEFT JOIN 
        MovieCompanies mc ON md.movie_id = mc.movie_id
)
SELECT 
    cd.title,
    cd.production_year,
    cd.total_cast,
    cd.total_companies,
    cd.actors,
    cd.company_names,
    CASE 
        WHEN cd.total_cast > 5 AND cd.total_companies > 2 THEN 'Popular'
        WHEN cd.total_cast > 3 AND cd.total_companies BETWEEN 1 AND 2 THEN 'Moderate'
        ELSE 'Less Known' 
    END AS popularity_category
FROM 
    CombinedDetails cd
WHERE 
    cd.production_year = cd.max_year_per_type 
ORDER BY 
    cd.total_cast DESC, 
    cd.production_year DESC
LIMIT 10;
