WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS cast_kind,
        k.keyword AS movie_keyword,
        CASE 
            WHEN t.production_year < 2000 THEN 'Classic'
            WHEN t.production_year >= 2000 AND t.production_year < 2010 THEN 'Recent'
            ELSE 'Modern'
        END AS era
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id 
    JOIN 
        aka_name a ON ci.person_id = a.person_id 
    JOIN 
        role_type r ON ci.role_id = r.id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id 
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id 
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%award%' OR it.info ILIKE '%nominated%'
),
ranked_movies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_kind,
        movie_keyword,
        era,
        ROW_NUMBER() OVER (PARTITION BY era ORDER BY production_year DESC) AS rank
    FROM 
        movie_data
)
SELECT 
    era,
    COUNT(*) AS total_movies,
    STRING_AGG(movie_title || ' (' || actor_name || ')', ', ') AS movies_details
FROM 
    ranked_movies
GROUP BY 
    era
HAVING 
    COUNT(*) > 1
ORDER BY 
    era;
