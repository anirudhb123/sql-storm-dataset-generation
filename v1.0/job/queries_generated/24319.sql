WITH RecursiveMovieInfo AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            GROUP_CONCAT(DISTINCT cn.name SEPARATOR ', ') AS name
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ) AS c ON t.id = c.movie_id
),
FilteredMovieInfo AS (
    SELECT
        m.title_id,
        m.title,
        m.production_year,
        m.company_name,
        m.movie_keyword,
        m.keyword_rank,
        COUNT(*) OVER(PARTITION BY m.title_id) AS keyword_count
    FROM
        RecursiveMovieInfo m
    WHERE
        m.production_year IS NOT NULL
        AND (m.company_name IS NOT NULL OR m.company_name != 'Unknown Company')
        AND m.keyword_rank <= 5
),
CorrelatedSubquery AS (
    SELECT 
        f.title_id,
        f.title,
        FIRST_VALUE(f.company_name) OVER(PARTITION BY f.title_id ORDER BY f.keyword_rank) AS first_company,
        SUM(f.keyword_count) OVER() AS total_keywords
    FROM 
        FilteredMovieInfo f
)
SELECT 
    f.title,
    f.production_year,
    f.company_name,
    STRING_AGG(DISTINCT f.movie_keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(f.movie_keyword) > 0 THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS keyword_status,
    COALESCE(MAX(c.role), 'No Role') AS actor_role
FROM 
    CorrelatedSubquery cs
LEFT JOIN cast_info c ON cs.title_id = c.movie_id
LEFT JOIN aka_name an ON c.person_id = an.person_id
LEFT JOIN role_type rt ON c.role_id = rt.id
WHERE 
    cs.total_keywords > 10
GROUP BY 
    f.title, f.production_year, f.company_name
HAVING 
    COUNT(f.title) > 1
ORDER BY 
    cs.total_keywords DESC, f.production_year ASC
LIMIT 100;
