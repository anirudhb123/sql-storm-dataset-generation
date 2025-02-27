WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY DENSE_RANK() OVER (ORDER BY COUNT(c.id) DESC)) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RelevantKeywords AS (
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
CommonRoles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        ci.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
FinalResult AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rk.keywords,
        cr.roles,
        mc.companies,
        mc.company_type,
        CASE 
            WHEN rm.rank_by_cast <= 3 THEN 'Top Cast'
            ELSE 'Other'
        END AS cast_benchmark
    FROM 
        RankedMovies rm
    LEFT JOIN 
        RelevantKeywords rk ON rm.movie_id = rk.movie_id
    LEFT JOIN 
        CommonRoles cr ON rm.movie_id = cr.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keywords,
    fr.roles,
    fr.companies,
    fr.company_type,
    fr.cast_benchmark
FROM 
    FinalResult fr
WHERE 
    fr.production_year IS NOT NULL
    AND fr.keywords IS NOT NULL
    AND fr.companies IS NOT NULL
ORDER BY 
    fr.production_year DESC, 
    fr.cast_benchmark ASC;
