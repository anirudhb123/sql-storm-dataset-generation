WITH ranked_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id
),
recent_movies AS (
    SELECT 
        title,
        production_year,
        actor_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)
SELECT 
    r.title,
    r.production_year,
    COALESCE(k.keyword, 'No keywords') AS keyword,
    COALESCE(p.info, 'No additional info') AS additional_info
FROM 
    recent_movies r
LEFT JOIN 
    movie_keyword mk ON r.title = (SELECT title FROM title WHERE id = mk.movie_id)
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON r.title = (SELECT title FROM title WHERE id = mi.movie_id) AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
LEFT JOIN 
    person_info p ON (SELECT person_id FROM cast_info WHERE movie_id = (SELECT id FROM title WHERE title = r.title)) = p.person_id
WHERE 
    r.production_year IS NOT NULL 
ORDER BY 
    r.production_year DESC, 
    r.actor_count DESC;
