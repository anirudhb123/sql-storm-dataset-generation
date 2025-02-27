WITH Recursive MovieTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        COALESCE(ka.name, 'Unknown') AS alternate_title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM title t
    LEFT JOIN aka_title ka ON t.id = ka.movie_id
), CastInfoWithRoles AS (
    SELECT 
        c.movie_id, 
        c.person_id, 
        c.note, 
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
), MovieCompanies AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT m.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        SUM(CASE WHEN mt.kind = 'Production' THEN 1 ELSE 0 END) AS production_companies
    FROM movie_companies m
    JOIN company_name cn ON m.company_id = cn.id
    JOIN company_type mt ON m.company_type_id = mt.id
    GROUP BY m.movie_id
), TitleKeyword AS (
    SELECT 
        m.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
), FinalMovieStats AS (
    SELECT 
        mt.title_id,
        mt.title, 
        mt.production_year, 
        mt.alternate_title,
        ci.person_id,
        ci.role_type,
        mc.company_count,
        tk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mc.company_count DESC) AS rank_by_companies
    FROM MovieTitles mt
    LEFT JOIN CastInfoWithRoles ci ON mt.title_id = ci.movie_id
    LEFT JOIN MovieCompanies mc ON mt.title_id = mc.movie_id
    LEFT JOIN TitleKeyword tk ON mt.title_id = tk.movie_id
)
SELECT 
    fms.title, 
    fms.production_year,
    fms.alternate_title,
    fms.person_id,
    fms.role_type,
    fms.company_count,
    fms.keywords,
    CASE 
        WHEN fms.rank_by_companies < 5 THEN 'Top Company Producers'
        WHEN fms.rank_by_companies IS NULL THEN 'No Companies Associated'
        ELSE 'Others' 
    END AS classification
FROM FinalMovieStats fms
WHERE fms.role_type IS NOT NULL 
    AND (fms.keywords IS NOT NULL OR fms.company_count > 0)
ORDER BY fms.production_year DESC, fms.company_count DESC;
