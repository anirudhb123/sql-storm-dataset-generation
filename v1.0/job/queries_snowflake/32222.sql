WITH RECURSIVE title_hierarchy AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.episode_of_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id,
        th.level + 1
    FROM 
        aka_title t
    INNER JOIN 
        title_hierarchy th ON t.episode_of_id = th.title_id
    WHERE 
        th.level < 5
), movie_company_info AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), title_info AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), player_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN at.kind_id = 1 THEN 1 ELSE 0 END) AS main_role_count
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.id
    GROUP BY 
        ci.movie_id
)
SELECT 
    ti.title,
    ti.production_year,
    mc.companies,
    mc.company_type,
    ps.cast_count,
    ps.main_role_count,
    th.level AS hierarchy_level
FROM 
    title_info ti
LEFT JOIN 
    movie_company_info mc ON ti.title_id = mc.movie_id
LEFT JOIN 
    player_statistics ps ON ti.title_id = ps.movie_id
LEFT JOIN 
    title_hierarchy th ON ti.title_id = th.title_id
WHERE 
    (ps.cast_count >= 5 OR mc.company_type IS NOT NULL)
ORDER BY 
    ti.production_year DESC,
    ti.title;
