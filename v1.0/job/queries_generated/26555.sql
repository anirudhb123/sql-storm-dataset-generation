WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ct.kind AS company_type,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS kc ON mk.keyword_id = kc.id
    WHERE 
        t.production_year >= 2000
        AND ct.kind LIKE '%Production%'
    GROUP BY 
        t.title, 
        t.production_year, 
        ak.name, 
        ct.kind
),
summary AS (
    SELECT 
        movie_title,
        AVG(keyword_count) AS avg_keywords_per_actor,
        COUNT(DISTINCT actor_name) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_title
)
SELECT 
    movie_title,
    avg_keywords_per_actor,
    actor_count
FROM 
    summary
WHERE 
    actor_count > 5
ORDER BY 
    avg_keywords_per_actor DESC;
