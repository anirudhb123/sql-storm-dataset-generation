WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT p.info, '; ') AS person_infos
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), ranked_movies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_names,
        md.keyword_count,
        md.company_types,
        md.person_infos,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.keyword_count DESC) AS rank
    FROM 
        movie_details md
)
SELECT 
    rm.rank,
    rm.title,
    rm.production_year,
    rm.actor_names,
    rm.keyword_count,
    rm.company_types,
    rm.person_infos
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
