
WITH matched_movies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        k.keyword AS movie_keyword,
        ct.kind AS company_type,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, ct.kind
)

SELECT 
    movie_title,
    production_year,
    actor_names,
    movie_keyword,
    company_type,
    actor_count
FROM 
    matched_movies
WHERE 
    actor_count > 2
ORDER BY 
    production_year DESC, movie_title;
