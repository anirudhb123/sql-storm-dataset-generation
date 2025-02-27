WITH filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        r.role
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        role_type r ON mi.info_type_id = r.id
    WHERE 
        t.production_year > 2000
        AND (k.keyword LIKE '%action%' OR k.keyword LIKE '%drama%')
),
actor_details AS (
    SELECT 
        a.name AS actor_name,
        t.title,
        t.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        filtered_movies t ON ci.movie_id = t.movie_id
    WHERE 
        ci.nr_order <= 3
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    STRING_AGG(DISTINCT ad.actor_name, ', ') AS top_actors,
    STRING_AGG(DISTINCT f.keyword, ', ') AS associated_keywords,
    STRING_AGG(DISTINCT f.company_name, ', ') AS production_companies
FROM 
    filtered_movies f
LEFT JOIN 
    actor_details ad ON f.title = ad.title AND f.production_year = ad.production_year
GROUP BY 
    f.movie_id, f.title, f.production_year
ORDER BY 
    f.production_year DESC, f.title;
