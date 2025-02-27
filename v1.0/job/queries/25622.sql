
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(k.id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_movie_role AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, a.name, r.role
),
movies_with_actors AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        amr.actor_name,
        amr.role_name,
        rt.keyword_count,
        rt.keywords
    FROM 
        ranked_titles rt
    LEFT JOIN 
        actor_movie_role amr ON rt.title_id = amr.movie_id
)
SELECT 
    mwa.title_id,
    mwa.title,
    mwa.production_year,
    COALESCE(mwa.actor_name, 'No Actor') AS actor_name,
    COALESCE(mwa.role_name, 'N/A') AS role_name,
    mwa.keyword_count,
    COALESCE(mwa.keywords, 'No Keywords') AS keywords
FROM 
    movies_with_actors mwa
ORDER BY 
    mwa.production_year DESC, 
    mwa.title ASC;
