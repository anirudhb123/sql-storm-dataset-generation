WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),

movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS character_name,
        COALESCE(c.note, 'No note') AS note,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),

company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        CASE WHEN mc.notes LIKE '%special%' THEN 'Special' ELSE 'Regular' END AS note_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    STRING_AGG(DISTINCT mc.company_name || ' (' || mc.company_type || ')', ', ') AS companies,
    STRING_AGG(DISTINCT ma.actor_name || ' as ' || COALESCE(ma.character_name, 'Unknown Character'), '; ') AS cast_details,
    COUNT(DISTINCT ma.actor_name) OVER (PARTITION BY m.movie_id) AS total_actors,
    m.rank
FROM 
    ranked_movies m
LEFT JOIN 
    movie_cast ma ON m.movie_id = ma.movie_id
LEFT JOIN 
    company_details mc ON m.movie_id = mc.movie_id
WHERE 
    m.production_year >= 2000
    AND (m.title ILIKE '%action%' OR m.title ILIKE '%thriller%')
GROUP BY 
    m.movie_id, m.title, m.production_year, m.rank
HAVING 
    COUNT(DISTINCT ma.actor_name) > 2
ORDER BY 
    m.production_year DESC, m.rank;
