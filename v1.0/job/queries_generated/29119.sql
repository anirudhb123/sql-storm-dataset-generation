WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        COUNT(DISTINCT ca.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    GROUP BY 
        t.title, t.production_year, k.keyword, c.kind
),
info_per_actor AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        pi.info AS actor_info,
        count(DISTINCT pi.info_type_id) AS info_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        person_info pi ON ci.person_id = pi.person_id
    GROUP BY 
        a.name, a.id, pi.info
),
final_benchmark AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.movie_keyword,
        md.company_type,
        md.actor_count,
        ia.actor_name,
        ia.actor_info,
        ia.info_count
    FROM 
        movie_details md
    JOIN 
        info_per_actor ia ON md.actor_count > 0
)
SELECT 
    movie_title,
    production_year,
    movie_keyword,
    company_type,
    actor_count,
    actor_name,
    actor_info,
    info_count
FROM 
    final_benchmark
WHERE 
    production_year > 2000
ORDER BY 
    production_year DESC, actor_count DESC;
