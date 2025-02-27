WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.company_id) AS production_companies,
        AVG(pi.info) FILTER (WHERE pi.info_type_id = 1) AS average_rating,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info_idx pi ON t.id = pi.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id
),
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
final_benchmark AS (
    SELECT 
        md.title,
        md.production_year,
        md.production_companies,
        md.average_rating,
        cd.actor_count,
        cd.actors,
        COALESCE(md.keywords, 'None') AS keywords_summary
    FROM 
        movie_details md
    FULL OUTER JOIN 
        cast_details cd ON md.movie_id = cd.movie_id
)
SELECT 
    title,
    production_year,
    COALESCE(production_companies, 0) AS total_companies,
    COALESCE(average_rating, 0) AS avg_rating,
    COALESCE(actor_count, 0) AS total_actors,
    LEFT(actors, 255) AS actor_list,
    keywords_summary
FROM 
    final_benchmark
WHERE 
    production_year >= 2000
ORDER BY 
    production_year DESC, 
    average_rating DESC NULLS LAST;
