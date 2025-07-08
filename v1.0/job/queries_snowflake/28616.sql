
WITH movie_data AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        k.keyword AS movie_keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year >= 2000
        AND k.keyword LIKE '%action%'
),
actor_stats AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title) AS movie_count,
        LISTAGG(DISTINCT movie_keyword, ', ') WITHIN GROUP (ORDER BY movie_keyword) AS keywords
    FROM 
        movie_data
    GROUP BY 
        actor_name
), 
benchmark_data AS (
    SELECT 
        actor_name,
        movie_count,
        keywords,
        RANK() OVER (ORDER BY movie_count DESC) AS actor_rank
    FROM 
        actor_stats
)
SELECT 
    actor_name,
    movie_count,
    keywords,
    actor_rank
FROM 
    benchmark_data
WHERE 
    actor_rank <= 10
ORDER BY 
    actor_rank;
