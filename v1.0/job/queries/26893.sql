WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.md5sum AS actor_hash,
        ct.kind AS company_type,
        k.keyword AS movie_keyword,
        pi.info AS person_info
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
        AND (k.keyword ILIKE '%action%' OR k.keyword ILIKE '%drama%')
),

ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        actor_hash,
        company_type,
        movie_keyword,
        person_info,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY movie_title ASC) AS rank
    FROM 
        movie_details
    WHERE 
        actor_name IS NOT NULL
)

SELECT 
    production_year,
    COUNT(*) AS total_movies,
    STRING_AGG(DISTINCT movie_title, '; ') AS movie_titles,
    STRING_AGG(DISTINCT actor_name || ' (' || actor_hash || ')', '; ') AS actors,
    STRING_AGG(DISTINCT company_type, '; ') AS companies,
    STRING_AGG(DISTINCT movie_keyword, '; ') AS keywords,
    AVG(CASE WHEN person_info IS NOT NULL THEN LENGTH(person_info) ELSE 0 END) AS avg_person_info_length
FROM 
    ranked_movies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
