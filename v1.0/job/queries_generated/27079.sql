WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
keyword_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
company_summary AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_actors,
    rm.actor_names,
    ks.keywords,
    cs.company_names,
    cs.company_types
FROM 
    ranked_movies rm
LEFT JOIN 
    keyword_summary ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    company_summary cs ON rm.movie_id = cs.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.total_actors DESC, 
    rm.production_year DESC;
