WITH movie_characteristics AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        a.imdb_index AS aka_imdb_index,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        n.gender AS actor_gender,
        ARRAY_AGG(DISTINCT p.info) AS person_infos
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        name n ON a.person_id = n.imdb_id
    LEFT JOIN 
        person_info p ON n.id = p.person_id 
    GROUP BY 
        a.id, a.name, a.imdb_index, t.id, t.title, t.production_year, k.keyword, c.kind, n.gender
),
benchmarking_results AS (
    SELECT 
        DISTINCT ON (aka_name) 
        aka_name,
        movie_title,
        production_year,
        actor_gender,
        COUNT(DISTINCT movie_keyword) AS keyword_count,
        COUNT(DISTINCT company_type) AS company_count,
        ARRAY_LENGTH(person_infos, 1) AS info_count
    FROM 
        movie_characteristics
    ORDER BY 
        aka_name, production_year DESC
)
SELECT 
    aka_name,
    movie_title,
    production_year,
    actor_gender,
    keyword_count,
    company_count,
    info_count
FROM 
    benchmarking_results
WHERE 
    actor_gender = 'F'
ORDER BY 
    production_year DESC, keyword_count DESC, company_count DESC;
