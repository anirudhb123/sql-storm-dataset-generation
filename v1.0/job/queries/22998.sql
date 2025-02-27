
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.movie_id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompleteResults AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_name,
        cd.company_type,
        mk.keywords,
        ROW_NUMBER() OVER (ORDER BY rm.actor_count DESC) AS overall_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.title = cd.company_name 
    LEFT JOIN 
        MovieKeywords mk ON rm.title = CAST(mk.movie_id AS VARCHAR)
    WHERE 
        rm.actor_count > 0
)

SELECT 
    title,
    production_year,
    actor_count,
    COALESCE(company_name, 'Independent') AS company_name, 
    COALESCE(company_type, 'None') AS company_type,
    COALESCE(keywords, 'No Keywords') AS keywords,
    overall_rank
FROM 
    CompleteResults
WHERE 
    (production_year > 2000 AND actor_count > 5) OR 
    (production_year <= 2000 AND overall_rank <= 10)
ORDER BY 
    production_year DESC, actor_count DESC;
