WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        COUNT(CASE WHEN ca.role_id IS NOT NULL THEN 1 END) AS actor_count,
        COUNT(DISTINCT ai.info) AS info_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ca ON t.id = ca.movie_id
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
keyword_info AS (
    SELECT 
        keywords,
        COUNT(*) AS keyword_count
    FROM 
        movie_data
    GROUP BY 
        keywords
),
actor_info AS (
    SELECT 
        actors,
        actor_count,
        COUNT(*) AS actor_count_total
    FROM 
        movie_data
    GROUP BY 
        actors, actor_count
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    ki.keywords,
    ki.keyword_count,
    ai.actors,
    ai.actor_count,
    md.info_count
FROM 
    movie_data md
JOIN 
    keyword_info ki ON md.keywords = ki.keywords
JOIN 
    actor_info ai ON md.actors = ai.actors
WHERE 
    md.production_year BETWEEN 1990 AND 2020
ORDER BY 
    md.production_year DESC, md.movie_title;
