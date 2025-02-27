
WITH enriched_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),
filtered_movie_info AS (
    SELECT 
        em.*,
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = em.movie_id) AS total_cast
    FROM 
        enriched_movie_info em
    WHERE 
        (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = em.movie_id) > 5 
        AND keywords IS NOT NULL
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.keywords,
    f.company_names,
    f.actor_names,
    LENGTH(f.keywords) AS keywords_length,
    LENGTH(f.actor_names) AS actor_names_length
FROM 
    filtered_movie_info f
ORDER BY 
    f.production_year DESC,
    keywords_length DESC;
