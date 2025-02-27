WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        1 AS level 
    FROM 
        aka_title mt 
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mh.level + 1 
    FROM 
        aka_title mt 
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieRoleCounts AS (
    SELECT 
        ci.movie_id, 
        rt.role AS role_name, 
        COUNT(ci.person_id) AS actor_count
    FROM 
        cast_info ci 
    JOIN 
        role_type rt ON ci.role_id = rt.id 
    GROUP BY 
        ci.movie_id, rt.role
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        ROW_NUMBER() OVER(PARTITION BY mh.level ORDER BY COUNT(mc.movie_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mh.level
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(SUM(mrc.actor_count), 0) AS total_actors,
    STRING_AGG(DISTINCT rc.role_name, ', ') AS roles
FROM 
    TopMovies tm
LEFT JOIN 
    MovieRoleCounts mrc ON tm.movie_id = mrc.movie_id
LEFT JOIN 
    cast_info ci ON tm.movie_id = ci.movie_id
LEFT JOIN 
    role_type rc ON ci.role_id = rc.id
WHERE 
    tm.rn <= 5
GROUP BY 
    tm.title, tm.production_year
ORDER BY 
    tm.production_year DESC, 
    total_actors DESC;
