WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL 
        AND mt.production_year >= 2000

    UNION ALL

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.total_cast_members,
        mc.cast_names,
        RANK() OVER (ORDER BY mc.total_cast_members DESC) AS cast_rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieCast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast_members,
    rm.cast_names,
    CASE 
        WHEN rm.total_cast_members IS NULL THEN 'No Cast Information'
        ELSE 'Cast Information Available'
    END AS cast_info_status
FROM 
    RankedMovies rm
WHERE 
    rm.cast_rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.cast_rank;
