WITH RECURSIVE MoviePaths AS (
    SELECT 
        c.movie_id,
        c.person_id,
        1 AS depth,
        CAST(a.name AS TEXT) AS actor_name,
        CAST(t.title AS TEXT) AS movie_title
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        mc.movie_id,
        mp.person_id,
        mp.depth + 1,
        mp.actor_name,
        t.title AS movie_title
    FROM 
        MoviePaths mp
    JOIN 
        complete_cast cc ON mp.movie_id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = mp.movie_id
    WHERE 
        t.production_year < 2020 AND 
        mp.depth < 5
)

SELECT 
    mp.actor_name,
    mp.movie_title,
    COUNT(DISTINCT cc.status_id) AS role_count,
    MAX(t.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT COALESCE(kw.keyword, 'unknown'), ', ') AS keywords,
    COALESCE(SUM(m.info_type_id), 0) AS total_info_entries,
    ROW_NUMBER() OVER (PARTITION BY mp.actor_name ORDER BY COUNT(DISTINCT cc.status_id) DESC) AS rank
FROM 
    MoviePaths mp
LEFT JOIN 
    complete_cast cc ON mp.movie_id = cc.movie_id 
LEFT JOIN 
    movie_info m ON m.movie_id = mp.movie_id 
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mp.movie_id 
LEFT JOIN 
    keyword kw ON kw.id = mk.keyword_id 
LEFT JOIN 
    aka_title t ON mp.movie_id = t.movie_id
WHERE 
    mp.depth <= 5 AND 
    (t.title LIKE '%Action%' OR t.title LIKE '%Drama%' OR mp.movie_title IS NOT NULL)
GROUP BY 
    mp.actor_name, mp.movie_title
HAVING 
    COUNT(DISTINCT cc.role_id) > 0
ORDER BY 
    rank,
    latest_movie_year DESC
LIMIT 50;

-- The query entails:
-- 1. Recursive CTE to explore the hierarchy of movies and casts.
-- 2. Left joins to gather additional data while preserving nulls.
-- 3. Aggregation with COUNT, MAX, and STRING_AGG for keyword collection.
-- 4. Rank calculation via window function.
-- 5. Use of complicated predicates combining NULL logic and filters with IN and LIKE.
