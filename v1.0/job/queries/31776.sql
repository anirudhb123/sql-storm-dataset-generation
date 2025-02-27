
WITH RECURSIVE CTE_MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        cte.depth + 1
    FROM 
        aka_title et
    INNER JOIN 
        CTE_MovieHierarchy cte ON et.episode_of_id = cte.movie_id
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MergedMovieInfo AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        mc.actor_count,
        STRING_AGG(DISTINCT kv.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        MovieCast mc ON a.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kv ON mk.keyword_id = kv.id
    GROUP BY 
        a.id, a.title, a.production_year, mc.actor_count
),
FinalBenchmark AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.actor_count,
        mh.keywords,
        ROW_NUMBER() OVER (ORDER BY mh.production_year DESC, mh.actor_count DESC) AS ranking,
        (SELECT COUNT(*) FROM aka_title WHERE production_year = mh.production_year) AS movies_in_year
    FROM 
        MergedMovieInfo mh
)
SELECT 
    fb.movie_id,
    fb.title,
    fb.production_year,
    fb.actor_count,
    fb.keywords,
    fb.ranking,
    fb.movies_in_year,
    COALESCE(
        (SELECT AVG(depth) FROM CTE_MovieHierarchy WHERE movie_id = fb.movie_id), 
        -1
    ) AS avg_depth_of_related
FROM 
    FinalBenchmark fb
WHERE 
    fb.actor_count IS NOT NULL 
    AND fb.keywords IS NOT NULL
ORDER BY 
    fb.ranking DESC, 
    fb.production_year ASC;
