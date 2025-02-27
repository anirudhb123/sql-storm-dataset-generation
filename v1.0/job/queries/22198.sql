
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        CAST(NULL AS INTEGER) AS parent_id,
        1 AS level
    FROM 
        aka_title
    WHERE 
        production_year BETWEEN 1990 AND 2020
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS lead_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    WHERE 
        mi.note IS NULL 
    GROUP BY 
        m.movie_id
),
CombinedMovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mc.lead_cast, 0) AS lead_cast,
        mid.info_details
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieCast mc ON mh.movie_id = mc.movie_id 
    LEFT JOIN 
        MovieInfo mid ON mh.movie_id = mid.movie_id 
    WHERE 
        mh.level <= 3 
)
SELECT 
    title, 
    production_year, 
    total_cast, 
    lead_cast, 
    info_details,
    CASE 
        WHEN total_cast = 0 THEN 'No cast'
        WHEN lead_cast > 0 THEN 'Has lead cast'
        ELSE 'Only supporting cast'
    END AS cast_summary
FROM 
    CombinedMovieData
ORDER BY 
    production_year DESC, 
    total_cast DESC 
LIMIT 100
OFFSET 20;
