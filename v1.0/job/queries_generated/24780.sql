WITH RecursiveMovieChain AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        mt.production_year,
        ml.linked_movie_id, 
        1 AS depth
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mt.id, 
        mt.title, 
        mt.production_year,
        ml.linked_movie_id, 
        depth + 1
    FROM 
        aka_title mt
    JOIN 
        movie_link ml ON mt.id = ml.movie_id
    JOIN 
        RecursiveMovieChain rmc ON ml.linked_movie_id = rmc.movie_id
)
SELECT 
    DISTINCT at.name AS actor_name,
    mt.movie_title,
    mt.production_year,
    rmc.depth,
    COALESCE(
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = mt.id), 0) AS company_count,
    CASE 
        WHEN mt.production_year IS NULL THEN 'UNKNOWN'
        ELSE CAST(mt.production_year AS TEXT) 
    END AS production_year_str,
    ROW_NUMBER() OVER(PARTITION BY mt.id ORDER BY rmc.depth DESC) AS rank
FROM 
    aka_name at
JOIN 
    cast_info ci ON at.person_id = ci.person_id
JOIN 
    RecursiveMovieChain rmc ON ci.movie_id = rmc.movie_id
JOIN 
    aka_title mt ON rmc.movie_id = mt.id
WHERE 
    at.name IS NOT NULL
    AND COALESCE(mt.production_year, 0) > 2000
    AND (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mt.id) > 5
ORDER BY 
    rank, 
    mt.production_year DESC
LIMIT 10
OFFSET 5;

-- To get a side effect and explore NULL logic
WITH TopActors AS (
    SELECT 
        at.id AS actor_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name at
    JOIN 
        cast_info ci ON at.person_id = ci.person_id
    GROUP BY 
        at.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) IS NOT NULL
)
SELECT 
    the_company.name AS company_name,
    CASE 
        WHEN ta.actor_id IS NULL THEN 'NO ACTOR'
        ELSE at.name 
    END AS actor_review,
    COUNT(DISTINCT mc.movie_id) AS filmography_length
FROM 
    company_name the_company
LEFT OUTER JOIN
    movie_companies mc ON the_company.id = mc.company_id
LEFT OUTER JOIN
    TopActors ta ON mc.movie_id IN (SELECT DISTINCT movie_id FROM complete_cast)
LEFT OUTER JOIN
    aka_name at ON ta.actor_id = at.person_id
GROUP BY 
    the_company.name, ta.actor_id, at.name
HAVING 
    COUNT(DISTINCT mc.movie_id) < 3
ORDER BY 
    company_name;
