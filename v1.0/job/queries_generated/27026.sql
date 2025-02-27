WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        a.name AS actor_name,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT a.name, ', ') AS all_actors,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword, c.name, a.name
),

actor_summary AS (
    SELECT 
        actor_name,
        COUNT(DISTINCT title_id) AS movies_played,
        STRING_AGG(DISTINCT title, ', ') AS movie_titles
    FROM 
        movie_details
    GROUP BY 
        actor_name
    HAVING 
        movies_played > 3
)

SELECT 
    md.title,
    md.production_year,
    md.keyword_count,
    md.all_actors,
    asum.actor_name,
    asum.movies_played,
    asum.movie_titles 
FROM 
    movie_details md
JOIN 
    actor_summary asum ON md.actor_name = asum.actor_name
ORDER BY 
    md.production_year DESC, md.title;
