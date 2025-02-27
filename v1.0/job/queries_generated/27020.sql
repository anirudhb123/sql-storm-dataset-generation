WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        r.role,
        COUNT(c.id) AS cast_count
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON a.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        a.id, a.title, a.production_year, r.role
),
top_movies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY role ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    t.title,
    t.production_year,
    t.role,
    t.cast_count
FROM 
    top_movies t
WHERE 
    t.rank <= 5
ORDER BY 
    t.role, 
    t.cast_count DESC;

-- Additional Query to demonstrate string processing logic
SELECT 
    km.keyword AS keyword,
    COUNT(m.id) AS keyword_usage,
    STRING_AGG(DISTINCT a.title, ', ') AS movies
FROM 
    keyword km
JOIN 
    movie_keyword mk ON km.id = mk.keyword_id
JOIN 
    aka_title m ON mk.movie_id = m.id
JOIN 
    aka_name a ON m.id = a.id
GROUP BY 
    km.keyword
HAVING 
    COUNT(m.id) > 10
ORDER BY 
    keyword_usage DESC;
