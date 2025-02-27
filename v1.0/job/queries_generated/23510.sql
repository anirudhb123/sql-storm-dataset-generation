WITH RECURSIVE MoviePaths AS (
    SELECT 
        m.id AS movie_id,
        ARRAY[m.id] AS path,
        1 AS depth,
        t.title AS title
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        cn.country_code = 'USA'
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        path || ml.linked_movie_id,
        depth + 1,
        t.title
    FROM 
        MoviePaths mp
    JOIN 
        movie_link ml ON mp.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.movie_id
    WHERE 
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'related')
        AND NOT ml.linked_movie_id = ANY(mp.path)
)
SELECT 
    mp.depth,
    COUNT(DISTINCT mp.movie_id) AS total_related_movies,
    STRING_AGG(DISTINCT t.title, ', ') AS related_titles
FROM 
    MoviePaths mp
JOIN 
    aka_title t ON mp.movie_id = t.movie_id
GROUP BY 
    mp.depth
HAVING 
    COUNT(DISTINCT mp.movie_id) > 1
ORDER BY 
    mp.depth DESC;

-- Second part: Generate movies with at least one actor from 'Interstellar'
WITH ActorsInInterstellar AS (
    SELECT 
        ci.movie_id
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.title ILIKE '%Interstellar%'
),
MoviesWithActors AS (
    SELECT 
        at.title,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        AVG(ci.nr_order) AS avg_order
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM ActorsInInterstellar)
    GROUP BY 
        at.title
)
SELECT 
    title,
    actor_count,
    CASE 
        WHEN actor_count > 5 THEN 'Ensemble Cast'
        ELSE 'Small Cast' 
    END AS cast_type,
    CASE 
        WHEN avg_order IS NOT NULL THEN ROUND(avg_order, 2)
        ELSE NULL 
    END AS avg_actor_order
FROM 
    MoviesWithActors
WHERE 
    actor_count IS NOT NULL
ORDER BY 
    actor_count DESC, title;

-- Final refinement: Find all movies containing 'space' keyword and released
-- after 2000 including any associated actor names.
SELECT 
    mt.title AS movie_title,
    ak.name AS actor_name,
    mt.production_year,
    COALESCE(mk.keyword, 'No Keywords') AS keyword
FROM 
    aka_title mt
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON mt.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    mt.production_year > 2000
    AND (mk.keyword ILIKE '%space%' OR mk.keyword IS NULL)
ORDER BY 
    mt.production_year DESC, mt.title;
