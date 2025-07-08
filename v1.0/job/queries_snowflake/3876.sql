
WITH movie_details AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        md.*,
        RANK() OVER (ORDER BY actor_count DESC) AS ranking
    FROM 
        movie_details md
)
SELECT 
    tm.movie_id,
    tm.movie_title,
    tm.production_year,
    tm.keywords,
    COALESCE(tc.total_companies, 0) AS total_companies
FROM 
    top_movies tm
LEFT JOIN 
    (SELECT 
         mc.movie_id, 
         COUNT(DISTINCT mc.company_id) AS total_companies
     FROM 
         movie_companies mc
     GROUP BY 
         mc.movie_id) tc ON tm.movie_id = tc.movie_id
WHERE 
    tm.ranking <= 10 
    AND COALESCE(tm.keywords, '') <> ''
ORDER BY 
    tm.ranking;
