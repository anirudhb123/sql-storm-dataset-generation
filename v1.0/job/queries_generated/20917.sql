WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
TitleWithKeywords AS (
    SELECT 
        t.title_id,
        t.title,
        k.keyword,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        RecursiveTitleCTE t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.title_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        k.keyword IS NOT NULL
    GROUP BY 
        t.title_id, t.title, k.keyword
    HAVING 
        COUNT(mk.keyword_id) > 1
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS actor_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    WHERE 
        m.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%production%')
    GROUP BY 
        m.movie_id
)
SELECT 
    t.title,
    t.production_year,
    tk.keyword,
    cs.actor_count,
    mc.company_count,
    COALESCE(NULLIF(cs.ordered_roles, 0), 'No Roles') AS roles_info,
    CASE 
        WHEN mc.company_count > 5 THEN 'High Production'
        WHEN mc.company_count BETWEEN 3 AND 5 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_level,
    ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS overall_rank
FROM 
    TitleWithKeywords tk
JOIN 
    RecursiveTitleCTE t ON t.title_id = tk.title_id
LEFT JOIN 
    CastStatistics cs ON cs.movie_id = t.title_id
LEFT JOIN 
    MovieCompanyInfo mc ON mc.movie_id = t.title_id
WHERE 
    t.rn = 1
    AND t.title LIKE '%Epic%'
ORDER BY 
    t.production_year DESC, tk.keyword;
