WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        CAST(NULL AS VARCHAR) AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = (SELECT MAX(production_year) FROM aka_title)

    UNION ALL

    SELECT
        ml.linked_movie_id AS movie_id,
        mt.title,
        mh.movie_id AS parent_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT
    mk.keyword,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    AVG(p_info.info IS NOT NULL) AS null_info_ratio,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_cast_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors
FROM 
    movie_keyword mk
JOIN 
    aka_title at ON mk.movie_id = at.id
LEFT JOIN 
    cast_info ci ON at.id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    person_info p_info ON a.person_id = p_info.person_id
WHERE 
    at.production_year >= 2000
    AND mk.keyword LIKE '%action%'
GROUP BY 
    mk.keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 5
ORDER BY 
    actor_count DESC
LIMIT 10;

-- Get the titles that are linked to at least one action movie produced after 2000.
SELECT DISTINCT 
    at.title
FROM 
    aka_title at
JOIN 
    movie_link ml ON at.id = ml.movie_id
JOIN 
    movie_keyword mk ON ml.linked_movie_id = mk.movie_id
WHERE 
    mk.keyword = 'action'
    AND mk.movie_id IN (
        SELECT DISTINCT movie_id
        FROM aka_title
        WHERE production_year > 2000
    );

-- Previous month's top 5 movies combining window functions
SELECT
    at.title,
    at.production_year,
    RANK() OVER (PARTITION BY at.production_year ORDER BY SUM(mk.keyword = 'action') DESC) AS action_rank,
    ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN mk.keyword = 'drama' THEN 1 ELSE 0 END) DESC) AS drama_rank
FROM 
    aka_title at
JOIN 
    movie_keyword mk ON at.id = mk.movie_id
WHERE 
    at.production_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1
GROUP BY 
    at.id

HAVING 
    action_rank <= 5;

-- Identify actors with akin names and their associated movies
SELECT 
    a.name AS actor_name,
    ARRAY_AGG(DISTINCT at.title) AS associated_movies,
    COALESCE(COUNT(DISTINCT ci.id), 0) AS role_count
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    aka_title at ON ci.movie_id = at.id
WHERE 
    a.name IN (SELECT DISTINCT name FROM aka_name WHERE md5sum IS NULL)
GROUP BY 
    a.id
HAVING 
    role_count >= 2
HAVING 
    (COUNT(DISTINCT at.id) > 1 OR COUNT(DISTINCT ci.movie_id) < 3)
ORDER BY 
    actor_name;
