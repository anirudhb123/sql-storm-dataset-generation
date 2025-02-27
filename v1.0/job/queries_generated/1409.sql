WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        ct.kind AS role_name,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY ci.person_id, ct.kind
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
TitlesAndCompanies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        mc.company_id,
        cn.name AS company_name
    FROM RankedTitles rt
    LEFT JOIN movie_companies mc ON rt.title_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
)
SELECT 
    ta.title,
    ta.production_year,
    COALESCE(aw.actor_count, 0) AS total_actors,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ac.id) AS distinct_roles,
    SUM(CASE WHEN ar.role_count IS NULL THEN 0 ELSE ar.role_count END) AS total_roles
FROM TitlesAndCompanies ta
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY movie_id
) aw ON ta.title_id = aw.movie_id
LEFT JOIN MoviesWithKeywords k ON ta.title_id = k.movie_id
LEFT JOIN ActorRoles ar ON ar.person_id IN (
    SELECT DISTINCT ci.person_id
    FROM cast_info ci
    WHERE ci.movie_id = ta.title_id
)
LEFT JOIN aka_title at ON ta.title_id = at.movie_id
LEFT JOIN aka_name an ON at.id = an.id
LEFT JOIN role_type rt ON ar.role_name = rt.id
WHERE ta.production_year >= 2000
GROUP BY ta.title, ta.production_year, k.keywords
ORDER BY ta.production_year DESC, ta.title;
