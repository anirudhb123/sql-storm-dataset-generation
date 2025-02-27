
WITH RECURSIVE MovieHierarchy AS (
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1 AS depth
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
RankedMovies AS (
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COUNT(ci.id) AS cast_count,
        RANK() OVER (ORDER BY m.production_year DESC, COUNT(ci.id) DESC) AS movie_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    rm.cast_count,
    rm.movie_rank,
    CASE 
        WHEN mh.depth > 0 THEN 'Sequel'
        ELSE 'Original'
    END AS movie_type,
    STRING_AGG(a.name, ', ') AS cast_names,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mh.movie_id AND mi.info_type_id IN (1, 2)) AS info_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON rm.id = mh.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name a ON a.person_id = ci.person_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, rm.cast_count, rm.movie_rank, mh.depth
HAVING 
    rm.cast_count > 2 AND
    (mh.production_year BETWEEN 2000 AND 2023 OR mh.production_year IS NULL)
ORDER BY 
    rm.movie_rank
FETCH FIRST 50 ROWS ONLY;
