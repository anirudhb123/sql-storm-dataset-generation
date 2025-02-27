WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.imdb_index) AS rank_within_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
TitleKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT cn.id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    tk.keywords,
    ci.total_cast,
    ci.roles,
    co.companies,
    co.total_companies,
    COALESCE(NULLIF(EXTRACT(YEAR FROM CURRENT_DATE) - rt.production_year, 0), 'Not Released Yet') AS age_of_movie
FROM RankedTitles rt
LEFT JOIN TitleKeywords tk ON rt.title_id = tk.movie_id
LEFT JOIN CastInfoWithRoles ci ON rt.title_id = ci.movie_id
LEFT JOIN CompanyInfo co ON rt.title_id = co.movie_id
WHERE rt.rank_within_year <= 10 
  AND (tk.keywords LIKE '%action%' OR ci.roles LIKE '%lead%')
ORDER BY rt.production_year DESC, rt.title;
