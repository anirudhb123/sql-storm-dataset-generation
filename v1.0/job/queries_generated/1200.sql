WITH RankedTitles AS (
    SELECT 
        a.title, 
        a.production_year, 
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS title_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        c.country_code IS NOT NULL
    GROUP BY 
        mc.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role,
        COUNT(ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.person_role_id IS NOT NULL
    GROUP BY 
        ci.movie_id, r.role
),
KeywordCount AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(c.company_count, 0) AS number_of_companies,
    COALESCE(k.keyword_count, 0) AS number_of_keywords,
    COALESCE(r.role_count, 0) AS number_of_roles,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    RankedTitles t
LEFT JOIN 
    CompanyMovies c ON t.id = c.movie_id
LEFT JOIN 
    CastRoles r ON t.id = r.movie_id
LEFT JOIN 
    KeywordCount k ON t.id = k.movie_id
WHERE 
    (c.company_count > 2 OR k.keyword_count > 5)
    AND r.role_count IS NOT NULL
ORDER BY 
    t.production_year DESC, 
    t.title_rank ASC;
