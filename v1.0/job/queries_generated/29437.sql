WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT an.name) AS actors,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        comp_cast_type c ON mc.company_type_id = c.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
final_results AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.company_type,
        md.actors,
        md.keywords,
        CASE 
            WHEN md.production_year >= 2020 THEN 'Recent Release'
            WHEN md.production_year >= 2010 THEN 'Modern Classic'
            ELSE 'Oldie'
        END AS era
    FROM 
        movie_details md
)
SELECT 
    *,
    LENGTH(actors) AS actor_count,
    LENGTH(keywords) AS keyword_count
FROM 
    final_results
ORDER BY 
    production_year DESC, movie_title;
