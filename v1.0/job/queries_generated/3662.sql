WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        ROW_NUMBER() OVER (ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
similar_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mk.keyword,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mk.keyword
)
SELECT 
    ak.name AS actor_name,
    rt.title,
    rt.production_year,
    rt.cast_count,
    sm.company_count,
    CASE 
        WHEN rt.cast_count > 5 THEN 'Ensemble Cast'
        WHEN rt.cast_count IS NULL THEN 'No Cast Information'
        ELSE 'Small Cast'
    END AS cast_category,
    EXTRACT(YEAR FROM AGE(NOW(), (SELECT MIN(t.production_year) FROM ranked_titles t WHERE t.cast_count > 1))) AS years_since_early_cast
FROM 
    ranked_titles rt
JOIN 
    cast_info ci ON rt.title_id = ci.movie_id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    similar_movies sm ON rt.title = sm.title 
WHERE 
    rt.rn <= 10 
    AND (sm.company_count IS NULL OR sm.company_count < 3)
ORDER BY 
    rt.production_year DESC, ak.name
LIMIT 50;
