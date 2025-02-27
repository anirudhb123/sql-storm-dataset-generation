WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        CAST(NULL AS INTEGER) AS parent_id
    FROM title AS m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id
    FROM title AS m
    INNER JOIN MovieHierarchy AS mh ON m.episode_of_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        r.role AS role,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info AS ci
    JOIN role_type AS r ON ci.role_id = r.id
    GROUP BY ci.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name, ', ') AS companies,
        COUNT(DISTINCT mc.id) AS company_count
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    GROUP BY mc.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cr.actor_count, 0) AS actor_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(mc.companies, 'No companies') AS companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS row_num
FROM MovieHierarchy AS mh
LEFT JOIN CastRoles AS cr ON mh.movie_id = cr.movie_id
LEFT JOIN MovieKeywords AS mk ON mh.movie_id = mk.movie_id
LEFT JOIN MovieCompanies AS mc ON mh.movie_id = mc.movie_id
WHERE mh.production_year IS NOT NULL
ORDER BY mh.production_year DESC, mh.title;
