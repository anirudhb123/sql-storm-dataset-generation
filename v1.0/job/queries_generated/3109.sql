WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS YearRank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS CompanyRank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FilteredMovies AS (
    SELECT 
        r.title,
        r.production_year,
        COUNT(DISTINCT cd.company_name) AS company_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyDetails cd ON r.title = cd.movie_id
    WHERE 
        r.YearRank = 1
    GROUP BY 
        r.title, r.production_year
),
KeywordStats AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk 
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
FinalOutput AS (
    SELECT 
        f.title,
        f.production_year,
        f.company_count,
        COALESCE(k.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies f
    LEFT JOIN 
        KeywordStats k ON f.title = k.movie_id
)
SELECT 
    fo.title,
    fo.production_year,
    fo.company_count,
    fo.keyword_count,
    CASE 
        WHEN fo.company_count > 5 THEN 'High'
        WHEN fo.company_count BETWEEN 1 AND 5 THEN 'Medium'
        ELSE 'Low'
    END AS CompanyCountCategory
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, fo.title;
