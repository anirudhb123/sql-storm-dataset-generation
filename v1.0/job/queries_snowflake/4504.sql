
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY a.name) AS title_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
CompletedMovies AS (
    SELECT 
        c.movie_id,
        COUNT(cc.id) AS complete_count
    FROM 
        complete_cast c
    LEFT JOIN 
        cast_info cc ON c.movie_id = cc.movie_id
    GROUP BY 
        c.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    rt.title_rank,
    cm.company_names,
    cm.company_count,
    cm.movie_id,
    COALESCE(cm.company_count, 0) AS company_count,
    CASE 
        WHEN cm.company_count IS NULL THEN 'No Companies'
        ELSE 'Has Companies'
    END AS company_status,
    c.complete_count
FROM 
    RankedTitles rt
LEFT JOIN 
    CompanyMovies cm ON rt.title_id = cm.movie_id
LEFT JOIN 
    CompletedMovies c ON rt.title_id = c.movie_id
WHERE 
    rt.title_rank = 1 
AND 
    (rt.production_year > 2000 OR cm.company_count > 2)
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
