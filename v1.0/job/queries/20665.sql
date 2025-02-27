
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CostliestMovies AS (
    SELECT
        m.movie_id,
        SUM(CASE WHEN m.note IS NOT NULL THEN 1 ELSE 0 END) AS costliest_score
    FROM 
        movie_companies m
    LEFT JOIN 
        company_type ct ON m.company_type_id = ct.id
    WHERE 
        ct.kind LIKE 'Production%'
    GROUP BY 
        m.movie_id
    HAVING 
        SUM(CASE WHEN m.note IS NOT NULL THEN 1 ELSE 0 END) > 2
),
CastDepartment AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors
    FROM 
        cast_info c
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id
)
SELECT 
    ct.title,
    ct.production_year,
    COALESCE(c.total_actors, 0) AS total_actors,
    COALESCE(cm.costliest_score, 0) AS costliest_score,
    CASE
        WHEN ct.title_rank = 1 THEN 'Top Title'
        WHEN ct.title_rank <= 5 THEN 'Top 5 Title'
        ELSE 'Other Title'
    END AS title_category
FROM 
    RankedTitles ct
LEFT JOIN 
    CastDepartment c ON ct.title_id = c.movie_id
LEFT JOIN 
    CostliestMovies cm ON ct.title_id = cm.movie_id
WHERE 
    ct.production_year = (SELECT MAX(production_year) FROM aka_title)
    AND (c.total_actors IS NULL OR c.total_actors > 5)
ORDER BY 
    ct.production_year DESC, 
    ct.title ASC;
