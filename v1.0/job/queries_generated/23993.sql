WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyStats AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies m
    LEFT JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
),
TitleKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    cs.company_count,
    cs.company_names,
    tk.keywords,
    CASE 
        WHEN rm.rank_by_cast <= 3 THEN 'Top Cast' 
        WHEN rm.rank_by_cast IS NULL THEN 'No Cast' 
        ELSE 'Other' 
    END AS cast_rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.title_id = cs.movie_id
LEFT JOIN 
    TitleKeywords tk ON rm.title_id = tk.movie_id
WHERE 
    (rm.production_year > 2000 AND cs.company_count IS NOT NULL) OR 
    (tk.keywords IS NOT NULL AND cs.company_names IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC
FETCH FIRST 10 ROW ONLY;
