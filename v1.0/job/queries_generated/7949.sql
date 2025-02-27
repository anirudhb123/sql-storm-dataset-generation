WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT m.id) AS company_count,
        COUNT(DISTINCT k.id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT k.id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
filtered_movies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.company_count,
        rm.keyword_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 10
)
SELECT 
    f.title,
    f.production_year,
    f.company_count,
    f.keyword_count,
    a.name AS top_actor,
    ARRAY_AGG(DISTINCT cn.name) AS production_companies
FROM 
    filtered_movies f
JOIN 
    complete_cast cc ON f.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
GROUP BY 
    f.movie_id, a.name
ORDER BY 
    f.production_year DESC, f.keyword_count DESC;
