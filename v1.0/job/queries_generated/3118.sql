WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
KeywordsPerMovie AS (
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
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.cast_count,
        kp.keywords,
        ci.company_name,
        ci.company_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordsPerMovie kp ON rm.title = (SELECT title FROM aka_title WHERE id = kp.movie_id LIMIT 1)
    LEFT JOIN 
        CompanyInfo ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id LIMIT 1)
)
SELECT 
    *,
    CASE 
        WHEN cast_count > 0 THEN 'Has Cast'
        ELSE 'No Cast'
    END AS cast_status,
    COALESCE(NULLIF(keywords, ''), 'No Keywords') AS keywords_status
FROM 
    MovieDetails
WHERE 
    production_year IS NOT NULL
ORDER BY 
    production_year DESC, cast_count DESC
LIMIT 10;
