
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY p.id) AS rank,
        a.id
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    WHERE 
        a.production_year >= 2000 AND 
        r.role IS NOT NULL
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.role,
    COALESCE(ci.companies, 'No Companies') AS companies,
    COALESCE(mk.keywords, 'No Keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.id = ci.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
WHERE 
    rm.rank = 1
ORDER BY 
    rm.production_year DESC, 
    rm.title ASC;
