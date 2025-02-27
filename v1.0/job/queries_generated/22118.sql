WITH RecursiveMovieCast AS (
    SELECT 
        c.movie_id, 
        a.name AS actor_name, 
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY c.movie_id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year,
        (SELECT COUNT(DISTINCT rw.person_id)
         FROM cast_info rw 
         WHERE rw.movie_id = m.id AND rw.person_role_id IS NOT NULL) AS real_actor_count
    FROM 
        aka_title m
    WHERE 
        m.production_year > 2000
        AND (m.producer_id IS NULL OR m.producer_id < 10) -- looking for odd cases
),
HeroMovies AS (
    SELECT 
        rc.movie_id, 
        rc.actor_name,
        rc.total_actors
    FROM 
        RecursiveMovieCast rc
    JOIN 
        FilteredMovies fm ON rc.movie_id = fm.movie_id
    WHERE 
        rc.actor_order <= 5 -- top 5 actors per movie
        AND total_actors > 5  -- only movies with more than 5 actors
)
SELECT 
    hm.movie_id, 
    hm.actor_name,
    fm.title,
    fm.production_year,
    CASE 
        WHEN hm.total_actors > 10 THEN 'Ensemble Cast'
        WHEN hm.total_actors BETWEEN 5 AND 10 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE((SELECT GROUP_CONCAT(DISTINCT k.keyword)
              FROM movie_keyword mk
              JOIN keyword k ON mk.keyword_id = k.id
              WHERE mk.movie_id = hm.movie_id), 'No Keywords') AS movie_keywords
FROM 
    HeroMovies hm
JOIN 
    FilteredMovies fm ON hm.movie_id = fm.movie_id
LEFT JOIN 
    movie_info mi ON fm.movie_id = mi.movie_id 
    AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office' LIMIT 1)
WHERE 
    mi.info IS NULL OR 
    (mi.info IS NOT NULL AND mi.note IS NOT NULL) -- observe the note if info exists
ORDER BY 
    fm.production_year DESC, 
    hm.actor_name;
