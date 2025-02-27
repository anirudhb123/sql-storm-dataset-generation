WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

MovieCompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, '; ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),

NotableMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        mcs.company_count,
        mcs.company_names,
        CASE 
            WHEN mcs.company_count > 3 THEN 'Notable'
            ELSE 'Regular'
        END AS movie_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCompanyStats mcs ON rm.movie_id = mcs.movie_id
    WHERE 
        rm.movie_rank <= 5
),

PopularKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    nm.movie_id,
    nm.title,
    nm.production_year,
    nm.company_count,
    nm.company_names,
    nm.movie_status,
    COALESCE(pk.keywords, 'No Keywords') AS keywords
FROM 
    NotableMovies nm
LEFT JOIN 
    PopularKeywords pk ON nm.movie_id = pk.movie_id
WHERE 
    nm.production_year > 2000
ORDER BY 
    nm.production_year DESC,
    nm.title ASC;
