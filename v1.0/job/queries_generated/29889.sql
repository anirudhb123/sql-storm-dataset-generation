WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(a.name) AS actor_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
        GROUP_CONCAT(DISTINCT c.kind) AS company_types
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type c ON mc.company_type_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 1990 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT a.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        movie_id
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    ac.actor_count,
    md.actor_names,
    md.movie_keywords,
    md.company_types
FROM 
    MovieDetails md
JOIN 
    ActorCount ac ON md.movie_id = ac.movie_id
ORDER BY 
    md.production_year DESC, 
    ac.actor_count DESC;

This query retrieves titles and related details of movies produced between 1990 and 2020, showcasing their actors, keywords, and company types while also counting actors per movie for an in-depth analysis of the movie landscape in that period.
