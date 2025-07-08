
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        NULL AS parent_title,
        0 AS level
    FROM aka_title mt
    WHERE mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title AS movie_title,
        mh.movie_title AS parent_title,
        mh.level + 1
    FROM aka_title et
    JOIN MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
CastRoles AS (
    SELECT 
        c.movie_id,
        r.role AS role_name,
        COUNT(c.id) AS num_cast
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id, r.role
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    GROUP BY mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT mi.info, '; ') WITHIN GROUP (ORDER BY mi.info) AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.parent_title,
    mh.level,
    cr.role_name,
    COALESCE(cr.num_cast, 0) AS num_cast,
    mc.company_count,
    COALESCE(mc.company_names, 'No Companies') AS company_names,
    COALESCE(mi.info_details, 'No Info Available') AS info_details
FROM MovieHierarchy mh
LEFT JOIN CastRoles cr ON mh.movie_id = cr.movie_id
LEFT JOIN MovieCompanies mc ON mh.movie_id = mc.movie_id
LEFT JOIN MovieInfo mi ON mh.movie_id = mi.movie_id
ORDER BY mh.level, mh.movie_title;
