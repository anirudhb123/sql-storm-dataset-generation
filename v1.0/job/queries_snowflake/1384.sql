WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
latest_movies AS (
    SELECT 
        lm.movie_id,
        lm.title,
        lm.production_year,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = lm.movie_id) AS keyword_count
    FROM 
        ranked_movies lm
    WHERE 
        lm.rn = 1
    AND lm.production_year = (SELECT MAX(production_year) FROM ranked_movies)
)
SELECT 
    lm.title,
    lm.production_year,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    ca.name AS actor_name,
    (SELECT COUNT(DISTINCT mc.company_id) 
     FROM movie_companies mc 
     WHERE mc.movie_id = lm.movie_id AND mc.company_type_id IS NOT NULL) AS company_count
FROM 
    latest_movies lm
LEFT JOIN 
    cast_info ci ON lm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ca ON ci.person_id = ca.person_id
LEFT JOIN 
    movie_info mi ON lm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    (SELECT movie_id, COUNT(*) AS keyword_count FROM movie_keyword GROUP BY movie_id) k ON lm.movie_id = k.movie_id
WHERE 
    (mi.info IS NULL OR mi.info NOT LIKE '%(film)%')
ORDER BY 
    lm.production_year DESC, lm.title;
