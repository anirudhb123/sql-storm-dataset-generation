WITH ranked_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS actor_names,
        k.keyword AS keyword
    FROM 
        aka_title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    ORDER BY 
        cast_count DESC
    LIMIT 10
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_count,
    rm.actor_names,
    ct.kind AS company_type
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_companies mc ON rm.movie_title ILIKE '%' || mc.movie_id || '%'
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    cn.country_code = 'USA'
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
