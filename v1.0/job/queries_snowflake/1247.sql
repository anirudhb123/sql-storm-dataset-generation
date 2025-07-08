WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
movie_details AS (
    SELECT 
        m.title, 
        m.production_year, 
        COALESCE(mn.info, 'No information') AS movie_note,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = m.id) AS keyword_count
    FROM 
        ranked_movies rm
    JOIN 
        aka_title m ON rm.title = m.title AND rm.production_year = m.production_year
    LEFT JOIN 
        movie_info mn ON m.id = mn.movie_id AND mn.info_type_id = (SELECT id FROM info_type WHERE info = 'Note')
    WHERE 
        rm.rn <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.movie_note,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 0 THEN 'Contains Keywords'
        ELSE 'No Keywords Found'
    END AS keyword_status
FROM 
    movie_details md
WHERE 
    (md.production_year >= 2000 OR md.movie_note LIKE '%action%')
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC
LIMIT 10;

