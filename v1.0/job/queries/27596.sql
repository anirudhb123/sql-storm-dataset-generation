WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT mc.company_id) DESC, COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),
top_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
),
movie_details AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT CONCAT(c.name, ' (', ct.kind, ')'), ', ') AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.keywords
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, md.title;
