WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.id IS NOT NULL
    
    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.depth + 1
    FROM 
        aka_title mt
    INNER JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) as rank,
        COUNT(c.person_id) AS total_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
NullCheckMovies AS (
    SELECT 
        m.title,
        COALESCE(MAX(i.info), 'No Info Available') AS info,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info i ON m.movie_id = i.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    r.rank AS Rank_Within_Year,
    COALESCE(nc.keyword_count, 0) AS Keyword_Count,
    CASE 
        WHEN r.total_cast = 0 THEN 'No Cast'
        ELSE 'Cast Present'
    END AS Cast_Presence
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies r ON mh.movie_id = r.movie_id
LEFT JOIN 
    NullCheckMovies nc ON mh.title = nc.title
WHERE 
    mh.depth = 0 
ORDER BY 
    mh.production_year DESC, 
    r.rank;