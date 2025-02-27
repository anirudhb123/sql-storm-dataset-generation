WITH RecursiveMoviePath AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS depth,
        m.production_year,
        NULL AS parent_movie_id
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
        AND m.production_year >= 2000
  
    UNION ALL
  
    SELECT 
        linked_movie.id AS movie_id,
        linked_movie.title,
        rm.depth + 1,
        linked_movie.production_year,
        rm.movie_id AS parent_movie_id
    FROM 
        RecursiveMoviePath rm
    JOIN 
        movie_link ml ON rm.movie_id = ml.movie_id
    JOIN 
        aka_title linked_movie ON ml.linked_movie_id = linked_movie.id
)

SELECT 
    rmp.title AS movie_title,
    rmp.production_year,
    COUNT(DISTINCT ai.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    CASE 
        WHEN COUNT(DISTINCT ak.name) > 5 THEN 'Many Cast Members'
        ELSE 'Few Cast Members'
    END AS cast_size_label,
    (SELECT AVG(COALESCE(CASE WHEN mi.info IS NULL THEN 0 ELSE 1 END, 0)) 
     FROM movie_info mi WHERE mi.movie_id = rmp.movie_id) AS info_presence_rate,
    ROW_NUMBER() OVER (PARTITION BY rmp.production_year ORDER BY rmp.depth DESC) AS rank_by_depth
FROM 
    RecursiveMoviePath rmp
LEFT JOIN 
    cast_info ci ON rmp.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
WHERE 
    ak.name IS NOT NULL AND ak.name != ''
GROUP BY 
    rmp.movie_id, rmp.title, rmp.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 0 AND COUNT(DISTINCT ak.name) <= 10
ORDER BY 
    rmp.production_year DESC, actor_count DESC;

WITH MovieInfo AS (
    SELECT
        m.id AS movie_id,
        COALESCE(mi.info, 'No Info') AS movie_detail,
        m.title,
        m.production_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
)

SELECT 
    m.movie_detail,
    m.title,
    m.production_year,
    CASE 
        WHEN m.movie_detail LIKE '%Award%' THEN 'Awarded'
        ELSE 'Not Awarded'
    END AS award_status,
    COUNT(DISTINCT mc.company_id) AS company_count
FROM 
    MovieInfo m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
GROUP BY 
    m.movie_detail, m.title, m.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    award_status DESC, m.production_year DESC;
