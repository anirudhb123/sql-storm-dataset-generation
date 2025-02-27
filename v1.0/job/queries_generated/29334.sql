WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT co.id) AS company_count,
        COUNT(DISTINCT mc.movie_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, COUNT(DISTINCT co.id) DESC, t.title) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
top_ranked_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        company_count,
        keyword_count
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.company_count,
    r.keyword_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT c.kind, ', ') AS company_types
FROM 
    top_ranked_movies r
LEFT JOIN 
    cast_info csi ON r.movie_id = csi.movie_id
LEFT JOIN 
    aka_name a ON csi.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
GROUP BY 
    r.movie_id, r.title, r.production_year, r.company_count, r.keyword_count
ORDER BY 
    r.production_year DESC, r.company_count DESC, r.keyword_count DESC;
