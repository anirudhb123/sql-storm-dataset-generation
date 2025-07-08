
WITH ranked_movies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
final_output AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.company_names,
        COALESCE(NULLIF(rm.keywords, ''), 'No keywords') AS keywords,
        ROW_NUMBER() OVER (ORDER BY rm.company_count DESC) AS rank
    FROM 
        ranked_movies rm
)
SELECT 
    rank,
    title,
    production_year,
    company_count,
    company_names,
    keywords
FROM 
    final_output
WHERE 
    rank <= 10
ORDER BY 
    rank;
