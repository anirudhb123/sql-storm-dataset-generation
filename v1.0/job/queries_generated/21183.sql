WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(ROUND(AVG(pi.info::integer), 2), 0) AS average_rating
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_keywords mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = m.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        movie_info_idx mii ON mii.movie_id = m.movie_id AND mii.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')
    LEFT JOIN 
        person_info pi ON pi.person_id = (SELECT person_id FROM cast_info ci WHERE ci.movie_id = m.movie_id LIMIT 1)
    WHERE 
        m.production_year IS NOT NULL AND 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.movie_id, m.title, m.production_year
)
SELECT 
    md.*,
    CASE 
        WHEN average_rating IS NULL THEN 'Not rated'
        WHEN average_rating > 8 THEN 'Excellent'
        WHEN average_rating BETWEEN 6 AND 8 THEN 'Good'
        ELSE 'Needs Improvement'
    END AS rating_description
FROM 
    movie_details md
JOIN 
    aka_name an ON an.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = md.movie_id)
WHERE 
    an.name ILIKE '%star%' OR 
    md.keywords LIKE '%action%'
ORDER BY 
    md.production_year DESC, 
    md.average_rating DESC NULLS LAST
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
