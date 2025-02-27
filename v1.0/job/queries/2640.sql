WITH movie_ranks AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        movie_ranks
    WHERE 
        rank_by_cast_count <= 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_companies mc ON tm.title_id = mc.movie_id
    LEFT JOIN 
        movie_keywords mk ON tm.title_id = mk.movie_id
    GROUP BY 
        tm.title_id, tm.title, tm.production_year, mk.keywords
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.production_companies,
    CASE 
        WHEN md.production_companies > 10 THEN 'High Production'
        WHEN md.production_companies BETWEEN 5 AND 10 THEN 'Medium Production'
        ELSE 'Low Production'
    END AS production_level
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC,
    md.production_companies DESC;
