WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        0 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title m
    WHERE 
        m.season_nr IS NULL  

    UNION ALL

    SELECT 
        e.id AS movie_id, 
        e.title, 
        e.production_year, 
        mh.level + 1,
        CAST(mh.path || ' > ' || e.title AS VARCHAR(255)) AS path
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id  
),
FilteredMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.level, 
        mh.production_year,
        COUNT(c.id) AS actor_count,  
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON c.movie_id = mh.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.level, mh.production_year
),
TopMovies AS (
    SELECT 
        fm.movie_id, 
        fm.title, 
        fm.production_year, 
        fm.actor_count,
        fm.actor_names,
        ROW_NUMBER() OVER (PARTITION BY fm.level ORDER BY fm.actor_count DESC) AS rn  
    FROM 
        FilteredMovies fm
    WHERE 
        fm.level = 0 AND fm.actor_count > 0  
)
SELECT 
    tm.*,
    CASE 
        WHEN tm.actor_count IS NULL THEN 'No Actors'
        WHEN tm.actor_count = 0 THEN 'Zero Actors'
        ELSE 'Valid Movie'
    END AS status,
    COALESCE(NULLIF(tm.title, ''), 'Untitled') AS effective_title  
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5  
ORDER BY 
    tm.actor_count DESC;