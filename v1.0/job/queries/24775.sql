WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY length(t.title) DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastStatistics AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'leading' THEN 1 ELSE 0 END) AS has_leading_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MoviesWithStats AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        cs.actor_count,
        cs.has_leading_role,
        cm.company_count,
        cm.company_names
    FROM 
        aka_title t
    LEFT JOIN 
        CastStatistics cs ON t.id = cs.movie_id
    LEFT JOIN 
        CompanyMovies cm ON t.id = cm.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.company_count,
    mw.company_names,
    CASE 
        WHEN mw.has_leading_role = 1 THEN 'Has Leading Role'
        ELSE 'No Leading Role'
    END AS role_description,
    (SELECT 
        string_agg(name, ', ') 
     FROM 
        (SELECT DISTINCT a.name 
         FROM aka_name a 
         JOIN cast_info ci ON a.person_id = ci.person_id 
         WHERE ci.movie_id = mw.title_id) AS actor_names) AS actor_names
FROM 
    MoviesWithStats mw
WHERE 
    mw.actor_count IS NOT NULL 
    AND mw.production_year > 2000
ORDER BY 
    mw.production_year DESC, 
    mw.actor_count DESC 
LIMIT 10;