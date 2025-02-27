WITH RECURSIVE movie_chain AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Base case: movies from 2000 onwards

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mc.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_chain mc ON ml.movie_id = mc.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id 
    WHERE 
        mc.level < 5  -- Limit depth of recursion to 5
)

SELECT 
    t.title AS original_movie,
    STRING_AGG(DISTINCT mc.title, ', ') AS linked_movies,
    COUNT(DISTINCT CASE WHEN c.role_id IS NOT NULL THEN c.person_id END) AS total_actors,
    MIN(t.production_year) AS earliest_production_year
FROM 
    movie_chain mc
LEFT JOIN 
    complete_cast cc ON mc.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.person_id
JOIN 
    aka_title t ON mc.movie_id = t.id
GROUP BY 
    mc.movie_id, t.title
HAVING 
    COUNT(DISTINCT c.role_id) > 0  -- Only keep movies with actors
ORDER BY 
    earliest_production_year DESC
LIMIT 10;

WITH actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        AVG(TIMESTAMP 'now' - pi.info::timestamp) AS avg_age,  -- Calculate average age based on person info
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ci.person_id = ak.person_id
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    WHERE 
        pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'birthdate')  -- Ensure we get birthdates only
    GROUP BY 
        ak.id
    HAVING 
        COUNT(DISTINCT ci.movie_id) >= 3  -- Get actors with at least 3 movies
)
SELECT 
    actor_name,
    movie_count,
    avg_age,
    COALESCE(NULLIF(keywords, ''), 'No keywords') AS keywords_list  -- Handling NULL keywords with a default
FROM 
    actor_info
ORDER BY 
    movie_count DESC
LIMIT 20;

SELECT 
    c1.movie_id,
    COUNT(c1.person_id) AS critical_count,
    COUNT(c2.person_id) FILTER (WHERE c2.role_id = 2) AS supporting_count,
    COUNT(c3.role_id) FILTER (WHERE c3.note IS NULL) AS uncredited_count
FROM 
    cast_info c1
LEFT JOIN 
    cast_info c2 ON c1.movie_id = c2.movie_id
LEFT JOIN 
    cast_info c3 ON c1.movie_id = c3.movie_id AND c3.note IS NULL
WHERE 
    c1.role_id = 1  -- Considering critical roles
GROUP BY 
    c1.movie_id
HAVING 
    COUNT(c1.person_id) > 5  -- More than 5 critical cast members
ORDER BY 
    critical_count DESC
LIMIT 15;

SELECT 
    n.name,
    m.title,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        ELSE m.production_year::text 
    END AS production_year,
    COALESCE(m.note, 'No additional info') AS movie_note,
    ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY n.name) AS row_num
FROM 
    aka_name n
JOIN 
    cast_info c ON n.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
WHERE 
    n.name ILIKE '%Smith%'  -- Find Smiths
    AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filter by movie kind
ORDER BY 
    m.production_year DESC, n.name
LIMIT 30;
