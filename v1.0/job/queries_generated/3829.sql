WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
),
top_movies AS (
    SELECT 
        title, production_year
    FROM 
        ranked_movies
    WHERE 
        rank <= 5
),
company_movies AS (
    SELECT 
        m.movie_id, 
        co.name AS company_name, 
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
keyworded_movies AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cm.company_name, 'Unknown') AS company_name,
    COALESCE(kw.keywords, 'No Keywords') AS movie_keywords
FROM 
    top_movies tm
LEFT JOIN 
    company_movies cm ON tm.production_year = cm.movie_id
LEFT JOIN 
    keyworded_movies kw ON tm.title = kw.movie_id
ORDER BY 
    tm.production_year DESC, 
    tm.title;
