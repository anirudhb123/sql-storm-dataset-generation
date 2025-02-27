WITH RecursiveTitleCTE AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        CAST(NULL AS text) AS previous_title
    FROM
        title t
    WHERE
        t.production_year >= 2000

    UNION ALL

    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.season_nr,
        t.episode_nr,
        r.previous_title
    FROM
        title t
    JOIN
        RecursiveTitleCTE r ON r.title_id = t.episode_of_id
    WHERE
        t.title IS NOT NULL
),

ActorRoles AS (
    SELECT
        a.person_id,
        a.name,
        c.movie_id,
        r.role AS acting_role,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY c.nr_order) AS role_order
    FROM
        aka_name a
    JOIN
        cast_info c ON a.person_id = c.person_id
    JOIN
        role_type r ON c.role_id = r.id
),

MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name || ' (' || ct.kind || ')') AS companies,
        SUM(CASE WHEN ct.kind = 'Distributor' THEN 1 ELSE 0 END) AS distributor_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    COALESCE(ar.name, 'Unknown Actor') AS actor_name,
    ar.acting_role,
    rt.season_nr,
    rt.episode_nr,
    COALESCE(mci.companies, '{}') AS movie_companies,
    COALESCE(mci.distributor_count, 0) AS distributor_count
FROM 
    RecursiveTitleCTE rt
LEFT JOIN 
    ActorRoles ar ON rt.title_id = ar.movie_id AND ar.role_order = 1
LEFT JOIN 
    MovieCompanyInfo mci ON rt.title_id = mci.movie_id
WHERE 
    rt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv'))
    AND rt.production_year IS NOT NULL
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC NULLS LAST
FETCH FIRST 100 ROWS ONLY;


