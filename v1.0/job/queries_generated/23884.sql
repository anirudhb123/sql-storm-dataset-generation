WITH RecursiveRoleHierarchy AS (
    SELECT role_id, role, 0 AS level
    FROM role_type
    WHERE role IS NOT NULL
    UNION ALL
    SELECT cr.role_id, rt.role, level + 1
    FROM cast_info cr
    JOIN RecursiveRoleHierarchy rt ON cr.role_id = rt.role_id
    WHERE cr.note IS NULL OR cr.note <> 'Unknown'
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        array_agg(DISTINCT k.keyword) AS keywords,
        COALESCE(cn.name, 'Unknown') AS company_name,
        pt.role
    FROM aka_title m
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN company_name cn ON cn.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN cast_info ci ON ci.movie_id = m.id
    LEFT JOIN RecursiveRoleHierarchy rt ON rt.role_id = ci.role_id
    LEFT JOIN person_info pi ON pi.person_id = ci.person_id
    GROUP BY m.id, m.title, m.production_year, cn.name, rt.role
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keywords,
        md.company_name,
        RANK() OVER (PARTITION BY md.production_year ORDER BY COUNT(DISTINCT md.role) DESC) AS role_rank
    FROM MovieDetails md
    WHERE md.production_year IS NOT NULL AND md.production_year > 2000
    GROUP BY md.movie_id, md.title, md.production_year, md.keywords, md.company_name
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keywords,
        company_name 
    FROM RankedMovies
    WHERE role_rank <= 5
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    string_agg(DISTINCT keyword, ', ') AS all_keywords,
    COALESCE((
        SELECT COUNT(*)
        FROM complete_cast cc
        WHERE cc.movie_id = fm.movie_id AND cc.status_id IS NULL
    ), 0) AS uninvolved_cast_count
FROM FilteredMovies fm
LEFT JOIN unnest(fm.keywords) AS keyword ON TRUE
GROUP BY fm.movie_id, fm.title, fm.production_year, fm.company_name
ORDER BY fm.production_year DESC, fm.title ASC
LIMIT 30;
