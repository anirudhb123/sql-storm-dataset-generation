WITH actor_movies AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    GROUP BY 
        a.name, t.title, t.production_year, t.kind_id
),
combined_info AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.kind_id,
        k.keyword AS movie_keyword,
        c.kind AS company_type,
        COUNT(CASE WHEN ki.info IS NOT NULL THEN 1 END) AS info_count
    FROM 
        actor_movies am
    LEFT JOIN 
        movie_keyword mk ON am.movie_title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON am.movie_title = mc.movie_id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        movie_info mi ON am.movie_title = mi.movie_id
    LEFT JOIN 
        info_type ki ON mi.info_type_id = ki.id
    GROUP BY 
        am.actor_name, am.movie_title, am.production_year, am.kind_id, k.keyword, c.kind
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    kind_id,
    STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT company_type, ', ') AS companies,
    SUM(info_count) AS total_info
FROM 
    combined_info
GROUP BY 
    actor_name, movie_title, production_year, kind_id
ORDER BY 
    actor_name, production_year DESC;
