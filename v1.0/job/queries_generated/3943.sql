WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(CASE WHEN c.id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY t.id) AS has_cast_info,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
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
    WHERE 
        co.country_code IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id, 
    rm.title, 
    rm.production_year, 
    COALESCE(cd.company_name, 'Unknown') AS company_name, 
    COALESCE(cd.company_type, 'Independent') AS company_type,
    rm.actor_count, 
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank <= 100 AND 
    (rm.actor_count > 5 OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
