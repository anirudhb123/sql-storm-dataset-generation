
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id, c.name, ct.kind
),
FinalResults AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(LISTAGG(DISTINCT mci.company_name || ' (' || mci.company_type || ')', ', '), 'No Companies') AS companies,
        tm.cast_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        MovieKeywords mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanyInfo mci ON tm.movie_id = mci.movie_id
    GROUP BY 
        tm.title, tm.production_year, mk.keywords, tm.cast_count
    ORDER BY 
        tm.production_year DESC,
        tm.cast_count DESC
)
SELECT 
    *,
    CASE 
        WHEN cast_count > 10 THEN 'High cast'
        WHEN cast_count BETWEEN 5 AND 10 THEN 'Medium cast'
        ELSE 'Low cast' 
    END AS cast_category,
    NULLIF(keywords, 'No Keywords') AS adjusted_keywords
FROM 
    FinalResults
WHERE 
    companies IS NOT NULL
    AND production_year IS NOT NULL
    AND title IS NOT NULL;
