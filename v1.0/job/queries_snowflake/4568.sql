
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN r.id IS NOT NULL THEN 1 ELSE 0 END) AS avg_has_role
    FROM 
        complete_cast m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        m.movie_id
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
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(hm.cast_count, 0) AS total_cast,
    COALESCE(hm.avg_has_role, 0) AS avg_role_flag,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(mci.companies, 'No Companies') AS production_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    HighRatedMovies hm ON rm.movie_id = hm.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
