WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
),
CompanyTitles AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ct.total_companies,
        kc.keyword_count,
        COUNT(DISTINCT c.id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        CASE 
            WHEN ct.total_companies IS NULL THEN 'No Companies'
            ELSE 'Companies Present'
        END AS company_status
    FROM 
        RankedTitles t
    LEFT JOIN 
        CompanyTitles ct ON t.title_id = ct.movie_id
    LEFT JOIN 
        KeywordCounts kc ON t.title_id = kc.movie_id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.title_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        t.title, t.production_year, ct.total_companies, kc.keyword_count
)
SELECT 
    *,
    SUM(total_cast) OVER () AS total_overall_cast,
    AVG(keyword_count) OVER () AS avg_keywords_per_movie,
    MAX(production_year) OVER () AS latest_production_year,
    COUNT(*) FILTER (WHERE company_status = 'Companies Present') OVER () AS movies_with_companies
FROM 
    FinalResults
WHERE 
    (production_year = (SELECT MAX(production_year) FROM RankedTitles)
    OR movie_title ILIKE '%The%')
    AND total_cast > (SELECT AVG(total_cast) FROM FinalResults)
ORDER BY 
    production_year DESC, movie_title;
