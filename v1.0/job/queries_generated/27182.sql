WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title AS mt
    JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    JOIN 
        cast_info AS ci ON mt.id = ci.movie_id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        mt.production_year >= 2000 
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.title, 
        mt.production_year, 
        ak.name, 
        ak.id
),
keyword_summary AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        ks.keywords,
        md.company_count
    FROM 
        movie_details AS md
    LEFT JOIN 
        keyword_summary AS ks ON md.actor_id = ks.movie_id
    ORDER BY 
        md.production_year DESC,
        md.company_count DESC,
        md.movie_title
)
SELECT 
    movie_title, 
    production_year, 
    actor_name, 
    keywords, 
    company_count 
FROM 
    final_benchmark
WHERE 
    company_count > 0
LIMIT 100;
