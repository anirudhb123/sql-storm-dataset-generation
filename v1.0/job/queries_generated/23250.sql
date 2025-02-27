WITH RECURSIVE film_series AS (
    SELECT 
        title.id AS title_id,
        title.title AS film_title,
        title.production_year,
        aka_name.name AS person_name,
        cast_info.nr_order,
        1 AS level
    FROM title
    JOIN cast_info ON title.id = cast_info.movie_id
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    WHERE title.production_year IS NOT NULL

    UNION ALL

    SELECT 
        linked_movie.title_id,
        linked_movie.film_title,
        linked_movie.production_year,
        aka_name.name,
        cast_info.nr_order,
        level + 1
    FROM film_series AS fs
    JOIN movie_link ON fs.title_id = movie_link.movie_id
    JOIN title AS linked_movie ON movie_link.linked_movie_id = linked_movie.id
    JOIN cast_info ON linked_movie.id = cast_info.movie_id
    JOIN aka_name ON cast_info.person_id = aka_name.person_id
    WHERE level < 5  -- Limiting depth to avoid infinite recursion
)

, actor_appearances AS (
    SELECT 
        aka_name.person_id,
        aka_name.name AS actor_name,
        COUNT(DISTINCT film_series.title_id) AS film_count,
        STRING_AGG(DISTINCT film_series.film_title, ', ') AS titles
    FROM film_series
    JOIN aka_name ON film_series.person_name = aka_name.name
    GROUP BY aka_name.person_id, aka_name.name
)

SELECT 
    aa.actor_name,
    aa.film_count,
    aa.titles,
    CASE 
        WHEN aa.film_count > 10 THEN 'Prolific Actor'
        WHEN aa.film_count BETWEEN 5 AND 10 THEN 'Emerging Actor'
        ELSE 'Newcomer'
    END AS actor_status,
    COALESCE(NULLIF(RANK() OVER (ORDER BY aa.film_count DESC), 0), 'Unranked') AS ranking
FROM 
    actor_appearances aa
WHERE 
    aa.film_count > (
        SELECT AVG(film_count) 
        FROM actor_appearances
    )
ORDER BY 
    aa.film_count DESC
LIMIT 50;

SELECT 
    cct.kind AS cast_type,
    COUNT(DISTINCT ci.movie_id) AS movie_count
FROM 
    cast_info ci
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
WHERE 
    at.production_year IS NOT NULL 
    AND at.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'f%')
GROUP BY 
    cct.kind
HAVING 
    COUNT(ci.movie_id) > (
        SELECT AVG(movie_count) FROM (
            SELECT COUNT(*) AS movie_count FROM cast_info GROUP BY movie_id
        ) AS sub
    )
ORDER BY 
    movie_count DESC;

