WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS keywords,
        a.name AS actor_name,
        a.md5sum AS actor_md5,
        ARRAY_AGG(DISTINCT c.kind) AS company_types,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        m.id, m.title, m.production_year, a.name, a.md5sum
),
ranked_movies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY keyword_count DESC) AS rank_by_keywords
    FROM 
        movie_details
)
SELECT 
    movie_id,
    movie_title,
    production_year,
    actor_name,
    actor_md5,
    company_types,
    keyword_count,
    person_info
FROM 
    ranked_movies
WHERE 
    rank_by_keywords <= 10
ORDER BY 
    keyword_count DESC, production_year DESC;
