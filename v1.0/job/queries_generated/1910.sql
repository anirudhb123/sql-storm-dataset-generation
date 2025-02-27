WITH movie_years AS (
    SELECT 
        production_year, 
        COUNT(*) AS movie_count 
    FROM 
        aka_title 
    GROUP BY 
        production_year 
    HAVING 
        COUNT(*) > 10
),
actor_movie_count AS (
    SELECT 
        a.person_id, 
        a.name,
        COUNT(distinct c.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
actor_highest_movie AS (
    SELECT 
        y.production_year, 
        am.person_id, 
        am.name, 
        am.movie_count,
        ROW_NUMBER() OVER (PARTITION BY y.production_year ORDER BY am.movie_count DESC) AS rn
    FROM 
        movie_years y
    JOIN 
        actor_movie_count am ON y.production_year IN (SELECT production_year FROM aka_title WHERE id IN (SELECT movie_id FROM cast_info WHERE person_id = am.person_id))
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    MAX(CASE WHEN ci.note IS NOT NULL THEN ci.note ELSE 'No role specified' END) AS role_note
FROM 
    actor_highest_movie ahm
JOIN 
    aka_name a ON ahm.person_id = a.person_id
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ahm.rn = 1 AND 
    m.production_year IS NOT NULL
GROUP BY 
    a.name, m.title, m.production_year
ORDER BY 
    m.production_year DESC, keyword_count DESC;
