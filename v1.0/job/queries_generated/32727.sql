WITH RECURSIVE ActorHierarchy AS (
    -- Base case: Select all actors
    SELECT
        ka.person_id,
        ka.name,
        1 AS level
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    WHERE
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    -- Recursive case: Find collaborators (other actors in the same movies)
    SELECT
        ka.person_id,
        ka.name,
        ah.level + 1 AS level
    FROM
        aka_name ka
    JOIN
        cast_info ci ON ka.person_id = ci.person_id
    JOIN
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN
        ActorHierarchy ah ON cc.subject_id = ah.person_id
    WHERE
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
)

-- Main query to get performance benchmarking
SELECT
    a.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(m.production_year) AS avg_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAX(ah.level) AS collaboration_level
FROM
    ActorHierarchy ah
JOIN
    aka_name a ON ah.person_id = a.person_id
JOIN
    cast_info ci ON a.person_id = ci.person_id
JOIN
    aka_title m ON ci.movie_id = m.id
GROUP BY
    a.name
HAVING
    COUNT(DISTINCT ci.movie_id) > 5
    AND MAX(ah.level) > 1
ORDER BY
    avg_year DESC;

-- Checking for NULL values in movie production year
SELECT
    m.id,
    m.title,
    CASE 
        WHEN m.production_year IS NULL THEN 'Year Not Available'
        ELSE m.production_year::text
    END AS production_year
FROM
    aka_title m
WHERE
    m.production_year IS NULL
ORDER BY
    m.title;

-- Bonus queries to evaluate keyword involvement in movies related to specific actors
SELECT
    ak.name AS actor_name,
    k.keyword AS movie_keyword,
    COUNT(mk.movie_id) AS keyword_count
FROM
    aka_name ak
JOIN
    cast_info ci ON ak.person_id = ci.person_id
JOIN
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN
    keyword k ON mk.keyword_id = k.id
WHERE
    ak.name ILIKE '%Smith%'
GROUP BY
    ak.name, k.keyword
ORDER BY
    keyword_count DESC;
