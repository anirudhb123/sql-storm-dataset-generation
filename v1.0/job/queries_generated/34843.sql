WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_id
    FROM 
        aka_title AS mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title AS et
    INNER JOIN 
        MovieHierarchy AS mh ON et.episode_of_id = mh.movie_id
),
CastWithRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS a ON ci.person_id = a.person_id
    JOIN 
        role_type AS rt ON ci.role_id = rt.id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mn.name) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS mn ON mc.company_id = mn.id
    GROUP BY 
        mc.movie_id
),
HighBudgetMovies AS (
    SELECT 
        mi.movie_id,
        SUM(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS numeric) ELSE 0 END) AS total_budget
    FROM 
        movie_info AS mi
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    WHERE 
        it.info = 'budget'
    GROUP BY 
        mi.movie_id
    HAVING 
        SUM(CASE WHEN it.info = 'budget' THEN CAST(mi.info AS numeric) ELSE 0 END) > 100000000
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cwr.actor_name, 'No Actors') AS actor_name,
    COALESCE(cwr.role, 'No Role') AS role,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(hbm.total_budget, 0) AS total_budget
FROM 
    MovieHierarchy AS mh
LEFT JOIN 
    CastWithRoles AS cwr ON mh.movie_id = cwr.movie_id 
LEFT JOIN 
    MovieCompanies AS mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    HighBudgetMovies AS hbm ON mh.movie_id = hbm.movie_id
ORDER BY 
    mh.production_year DESC,
    mh.title;
