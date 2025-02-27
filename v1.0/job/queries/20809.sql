WITH RECURSIVE TitleHierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
    UNION ALL
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        th.level + 1
    FROM 
        aka_title t
    JOIN 
        TitleHierarchy th ON t.episode_of_id = th.title_id
),
CastRoleCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieInfoDetail AS (
    SELECT 
        m.id AS movie_id,
        MAX(m.production_year) AS latest_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        MIN(mi.info) AS first_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    th.title_id,
    th.title,
    th.production_year,
    th.level,
    r.role_count,
    mi.latest_year,
    mi.keywords,
    CASE 
        WHEN cs.company_count IS NULL THEN 'No Companies'
        ELSE cs.company_count || ' Companies: ' || cs.companies
    END AS company_stats
FROM 
    TitleHierarchy th
LEFT JOIN 
    CastRoleCount r ON th.title_id = r.movie_id
LEFT JOIN 
    MovieInfoDetail mi ON th.title_id = mi.movie_id
LEFT JOIN 
    CompanyStats cs ON th.title_id = cs.movie_id
WHERE 
    th.level > 1
ORDER BY 
    th.production_year DESC, th.title;
