WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM cast_info ci
    JOIN role_type r ON ci.role_id = r.id
    GROUP BY ci.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.company_id) AS company_count
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, c.name, ct.kind
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    tt.title,
    tt.production_year,
    r.actor_count,
    r.roles,
    cm.company_name,
    cm.company_type,
    cm.company_count,
    mk.keywords,
    CASE 
        WHEN tt.production_year < 2000 THEN 'Classic' 
        WHEN tt.production_year BETWEEN 2000 AND 2010 THEN 'Modern' 
        ELSE 'Recent'
    END AS era,
    NULLIF(CASE 
        WHEN COUNT(mk.keywords) > 0 THEN STRING_AGG(DISTINCT mk.keywords, ', ')
        ELSE 'No Keywords'
    END, 'No Keywords') AS keyword_info
FROM RankedTitles tt
LEFT JOIN CastInfoWithRoles r ON tt.title_id = r.movie_id
LEFT JOIN CompanyMovies cm ON tt.title_id = cm.movie_id 
LEFT JOIN MovieKeywords mk ON tt.title_id = mk.movie_id
GROUP BY 
    tt.title,
    tt.production_year,
    r.actor_count,
    r.roles,
    cm.company_name,
    cm.company_type,
    cm.company_count
ORDER BY 
    tt.production_year DESC,
    tt.title ASC
LIMIT 50;
