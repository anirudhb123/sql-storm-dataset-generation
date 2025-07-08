
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        m.company_id,
        c.name AS company_name
    FROM 
        RankedTitles rt
    LEFT JOIN 
        movie_companies m ON rt.title_id = m.movie_id
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        rt.title_rank <= 5
),
KeywordCounts AS (
    SELECT 
        mk.movie_id AS title_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        COUNT(DISTINCT c.id) AS unique_companies
    FROM 
        TopMovies t
    LEFT JOIN 
        KeywordCounts kc ON t.title_id = kc.title_id
    LEFT JOIN 
        movie_companies mc ON t.title_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id 
    GROUP BY 
        t.title, t.production_year, kc.keyword_count
)
SELECT 
    fr.title,
    fr.production_year,
    fr.keyword_count,
    fr.unique_companies,
    CASE 
        WHEN fr.unique_companies > 3 THEN 'Diverse'
        WHEN fr.unique_companies = 0 THEN 'Independent'
        ELSE 'Standard'
    END AS company_diversity
FROM 
    FinalResults fr
WHERE 
    fr.keyword_count > 2
ORDER BY 
    fr.production_year DESC, fr.title;
