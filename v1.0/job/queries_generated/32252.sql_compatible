
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        CAST(NULL AS integer) AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id,
        et.title,
        et.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM 
        aka_title et
    INNER JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
ActorRolls AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        ci.movie_id,
        ci.person_role_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        COALESCE(mc.company_count, 0) AS company_count,
        mc.companies,
        mh.level
    FROM 
        MovieHierarchy mh
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT actor_id) AS actor_count
        FROM 
            ActorRolls
        GROUP BY 
            movie_id
    ) ac ON mh.movie_id = ac.movie_id
    LEFT JOIN 
        MovieCompanies mc ON mh.movie_id = mc.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.company_count,
    fm.companies,
    CASE 
        WHEN fm.actor_count > 5 THEN 'Popular'
        WHEN fm.actor_count BETWEEN 3 AND 5 THEN 'Moderate'
        ELSE 'Less Known'
    END AS movie_status,
    (SELECT AVG(actor_count) FROM FilteredMovies) AS average_actors
FROM 
    FilteredMovies fm
WHERE 
    (fm.level = 1 AND fm.company_count > 0)
ORDER BY 
    fm.production_year DESC, 
    fm.actor_count DESC;
