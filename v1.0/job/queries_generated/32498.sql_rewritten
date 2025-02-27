WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    
    SELECT 
        t.id, 
        t.title, 
        t.production_year,
        mh.level + 1 AS level
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
MovieDuration AS (
    
    SELECT 
        t.production_year,
        COUNT(DISTINCT c.person_id) AS avg_cast_count,
        COUNT(DISTINCT t.id) AS movie_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.production_year
),
RankedMovies AS (
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        md.avg_cast_count,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY md.avg_cast_count DESC) AS rank_within_year
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieDuration md ON mh.production_year = md.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.avg_cast_count,
    rm.rank_within_year,
    ak.name AS actor_name,
    COALESCE(ci.note, 'No role description available') AS role_description,
    CASE 
        WHEN rm.rank_within_year <= 5 THEN 'Top Ranking'
        ELSE 'Lower Ranking'
    END AS ranking_category
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    rm.production_year IS NOT NULL
ORDER BY 
    rm.production_year DESC, 
    rm.rank_within_year;