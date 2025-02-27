WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        h.depth + 1
    FROM 
        MovieHierarchy h
    JOIN 
        movie_link ml ON h.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        m.production_year >= 2000
), ActorCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), MovieInfo AS (
    SELECT
        a.title,
        a.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COALESCE(ac.actor_count, 0) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        ActorCount ac ON a.id = ac.movie_id
    WHERE 
        a.production_year BETWEEN 2000 AND 2023 
)
SELECT 
    mi.title,
    mi.production_year,
    mi.actor_count,
    CASE 
        WHEN mi.actor_count > 5 THEN 'Highly Cast'
        WHEN mi.actor_count > 0 THEN 'Moderately Cast'
        ELSE 'No Cast'
    END AS cast_status
FROM 
    MovieInfo mi
WHERE 
    mi.rank <= 10
ORDER BY 
    mi.production_year DESC, 
    mi.actor_count DESC;

-- Incorporating NULL checks and outer joins to analyze missing data
SELECT 
    n.name,
    COALESCE(m.title, 'No Title') AS movie_title,
    CASE 
        WHEN n.id IS NULL THEN 'Unrecorded Actor'
        ELSE 'Recorded Actor'
    END AS actor_status
FROM 
    name n
LEFT JOIN 
    cast_info ci ON n.id = ci.person_id
LEFT JOIN 
    aka_title m ON ci.movie_id = m.id
WHERE 
    n.gender IS NOT NULL AND
    (m.production_year IS NULL OR m.production_year > 2010)
ORDER BY 
    n.name;

-- Final performance benchmarking display summarizing actor roles and movie links.
SELECT 
    c.role_id,
    r.role,
    COUNT(DISTINCT m.id) AS linked_movies,
    AVG(COALESCE(m.production_year, 0)) AS avg_production_year,
    SUM(CASE WHEN m.production_year < 2015 THEN 1 ELSE 0 END) AS pre_2015_count
FROM 
    cast_info c
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_link ml ON c.movie_id = ml.movie_id
LEFT JOIN 
    aka_title m ON ml.linked_movie_id = m.id
GROUP BY 
    c.role_id, r.role
ORDER BY 
    linked_movies DESC, 
    avg_production_year DESC;
