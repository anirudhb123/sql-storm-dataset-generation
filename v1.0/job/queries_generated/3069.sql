WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        MAX(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.company_count,
        cs.main_company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    WHERE 
        rank <= 5 AND (cs.company_count IS NULL OR cs.company_count > 1)
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.company_count, 0) AS company_count,
    f.main_company_type,
    (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
     FROM movie_keyword mk 
     JOIN keyword k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = f.movie_id) AS keywords
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC;
