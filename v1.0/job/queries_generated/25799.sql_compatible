
WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
ranked_movies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        actor_names,
        keywords,
        company_names,
        ROW_NUMBER() OVER (PARTITION BY kind_id ORDER BY production_year DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.kind_id,
    rm.actor_names,
    rm.keywords,
    rm.company_names
FROM 
    ranked_movies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.kind_id, rm.production_year DESC;
