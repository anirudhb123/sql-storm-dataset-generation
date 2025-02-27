WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        CAST(NULL AS text) AS parent_movie,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.movie_title AS parent_movie,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
MovieStats AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        AVG(CASE WHEN cc.nr_order IS NOT NULL THEN cc.nr_order ELSE 0 END) AS avg_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info cc ON mh.movie_id = cc.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year
),
CompanyMovieStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name m ON mc.company_id = m.id
    GROUP BY 
        mc.movie_id
),
FinalStats AS (
    SELECT 
        ms.movie_id,
        ms.movie_title,
        ms.production_year,
        COALESCE(cs.company_count, 0) AS company_count,
        ms.total_cast,
        ms.avg_order,
        CASE 
            WHEN ms.total_cast > 10 THEN 'Large Cast'
            WHEN ms.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
            ELSE 'Small Cast'
        END AS cast_size
    FROM 
        MovieStats ms
    LEFT JOIN 
        CompanyMovieStats cs ON ms.movie_id = cs.movie_id
)
SELECT 
    f.movie_title,
    f.production_year,
    f.total_cast,
    f.avg_order,
    f.company_count,
    f.cast_size
FROM 
    FinalStats f
WHERE 
    f.production_year >= 2000
    AND (f.cast_size = 'Large Cast' OR f.company_count > 2)
ORDER BY 
    f.production_year DESC, 
    f.total_cast DESC
LIMIT 10;
