
WITH RankedMovies AS (
    SELECT
        a.id AS aka_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM aka_title t
    JOIN aka_name a ON a.id = t.id
    WHERE t.production_year IS NOT NULL AND t.title IS NOT NULL
),
CompanyMovies AS (
    SELECT
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
TitleWithKeywords AS (
    SELECT
        t.id AS title_id,
        t.title,
        ARRAY_AGG(k.keyword) AS keywords
    FROM aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY t.id, t.title
),
CorrelatedSubquery AS (
    SELECT
        c.person_id,
        c.movie_id,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM complete_cast cc
                WHERE cc.movie_id = c.movie_id
                AND cc.status_id = 1
            ) THEN 'Complete'
            ELSE 'Incomplete'
        END AS cast_status
    FROM cast_info c
)
SELECT
    r.title,
    r.production_year,
    r.year_rank,
    cm.company_name,
    cm.company_type,
    tk.keywords,
    cs.cast_status,
    CASE 
        WHEN cm.total_companies IS NULL THEN 'Unknown' 
        ELSE CAST(cm.total_companies AS VARCHAR) 
    END AS companies_count
FROM RankedMovies r
LEFT JOIN CompanyMovies cm ON r.aka_id = cm.movie_id
LEFT JOIN TitleWithKeywords tk ON r.aka_id = tk.title_id
LEFT JOIN CorrelatedSubquery cs ON cs.movie_id = r.aka_id
WHERE r.year_rank <= 5
AND (tk.keywords IS NULL OR ARRAY_SIZE(tk.keywords) > 2)
ORDER BY r.production_year DESC, tk.keywords;
