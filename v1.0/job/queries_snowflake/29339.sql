WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name,
        r.role AS person_role,
        ak.name AS actor_name,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id AND cc.movie_id = ci.movie_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, r.role, ak.name
),
actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT movie_title) AS movies
    FROM 
        movie_details
    GROUP BY 
        actor_name
)
SELECT 
    actor_name,
    movie_count,
    movies,
    (SELECT COUNT(*) FROM company_name) AS total_companies,
    (SELECT AVG(company_count) FROM movie_details) AS avg_companies_per_movie
FROM 
    actor_summary
ORDER BY 
    movie_count DESC
LIMIT 10;
