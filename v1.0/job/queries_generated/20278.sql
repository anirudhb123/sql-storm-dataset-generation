WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
FilteredCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        c.person_id,
        c.note,
        r.role
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    WHERE c.nr_order IS NOT NULL AND c.note IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
TitleWithKeywords AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mt
    JOIN keyword k ON mt.keyword_id = k.id
    GROUP BY mt.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    rc.person_id,
    ca.gender,
    cd.company_names,
    tk.keywords,
    ROW_NUMBER() OVER (PARTITION BY tt.production_year ORDER BY tm.total_companies DESC) AS total_comp_rnk
FROM RankedTitles tt
LEFT JOIN FilteredCast rc ON rc.movie_id = tt.title_id
LEFT JOIN name ca ON rc.person_id = ca.imdb_id AND ca.gender IS NOT NULL
LEFT JOIN CompanyDetails cd ON cd.movie_id = tt.title_id
LEFT JOIN TitleWithKeywords tk ON tk.movie_id = tt.title_id
WHERE 
    tt.rn <= 5 
    AND (ca.name_pcode_cf IS NULL OR ca.name_pcode_cf NOT LIKE 'A%')
ORDER BY 
    tt.production_year, 
    total_comp_rnk, 
    tt.title
LIMIT 100;
