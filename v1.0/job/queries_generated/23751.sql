WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(AVG(CASE WHEN c.role_id IS NOT NULL THEN 1.0 ELSE NULL END), 0) OVER (PARTITION BY t.id) AS avg_roles,
        -- Some intriguing string manipulation using IMDB index
        CASE 
            WHEN LENGTH(t.imdb_index) <= 4 THEN 'Short IMDB'
            ELSE 'Long IMDB' 
        END AS imdb_index_category
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre' LIMIT 1)
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        COALESCE(t.production_year, 0) > 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyCTE AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(CASE WHEN c.kind IS NOT NULL THEN c.kind ELSE 'Unknown' END, ', ') AS company_kinds,
        COUNT(DISTINCT m.company_id) AS distinct_companies
    FROM 
        movie_companies m
    LEFT JOIN 
        company_type c ON m.company_type_id = c.id
    GROUP BY 
        mc.movie_id
    HAVING 
        COUNT(*) > 1
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.avg_roles,
    r.imdb_index_category,
    COALESCE(cc.company_kinds, 'No Companies') AS company_kinds,
    COALESCE(cc.distinct_companies, 0) AS total_companies,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = r.movie_id AND ci.note IS NOT NULL) AS note_roles_count
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    CompanyCTE cc ON r.movie_id = cc.movie_id
ORDER BY 
    r.production_year DESC, r.avg_roles DESC
FETCH FIRST 50 ROWS ONLY;
