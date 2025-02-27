WITH RECURSIVE hierarchy AS (
    SELECT 
        c.id AS company_id, 
        c.name AS company_name, 
        m.id AS movie_id,
        t.title AS movie_title,
        1 AS level
    FROM 
        company_name c
    JOIN 
        movie_companies mc ON c.id = mc.company_id
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    WHERE 
        c.country_code = 'USA'

    UNION ALL

    SELECT 
        ch.id AS company_id,
        ch.name AS company_name,
        m.id AS movie_id,
        t.title AS movie_title,
        h.level + 1
    FROM 
        company_name ch
    JOIN 
        movie_companies mc ON ch.id = mc.company_id
    JOIN 
        aka_title t ON mc.movie_id = t.movie_id
    JOIN 
        hierarchy h ON ch.id = h.company_id
    WHERE 
        h.level < 5  -- limiting to depth 5 for recursive query
)

SELECT 
    h.company_name,
    COUNT(DISTINCT h.movie_id) AS total_movies,
    STRING_AGG(DISTINCT h.movie_title, '; ') AS movie_titles,
    AVG(t.production_year) AS avg_production_year,
    SUM(NOT mc.note IS NULL::integer) as movies_with_notes
FROM 
    hierarchy h
JOIN 
    aka_title t ON h.movie_id = t.id
JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
GROUP BY 
    h.company_name
HAVING 
    COUNT(DISTINCT h.movie_id) > 1
ORDER BY 
    total_movies DESC;

-- Additionally, let's find movies with keyword associations and their genre
SELECT 
    t.title AS movie_title,
    k.keyword AS keyword,
    COUNT(DISTINCT cm.company_id) AS total_companies
FROM 
    aka_title t
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies cm ON t.id = cm.movie_id
GROUP BY 
    t.title, k.keyword
HAVING 
    total_companies > 2
ORDER BY 
    total_companies DESC;

-- Finally, let's check cast information for movies with more than 3 casting roles
SELECT 
    t.title AS movie_title,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    STRING_AGG(DISTINCT a.name, ', ') AS cast_members
FROM 
    aka_title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    NOT ci.note IS NULL
GROUP BY 
    t.title
HAVING 
    COUNT(DISTINCT ci.person_id) > 3
ORDER BY 
    total_cast DESC;
