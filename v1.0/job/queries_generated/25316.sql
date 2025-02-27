WITH actor_movies AS (
    SELECT 
        akn.name AS actor_name,
        akn.person_id,
        title.title AS movie_title,
        title.production_year,
        string_agg(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_name akn
    JOIN 
        cast_info ci ON akn.person_id = ci.person_id
    JOIN 
        title ON ci.movie_id = title.id
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        akn.name, akn.person_id, title.title, title.production_year
),

movie_details AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        count(DISTINCT ci.person_id) AS total_actors,
        string_agg(DISTINCT cn.name, ', ') AS companies,
        string_agg(DISTINCT rt.role, ', ') AS roles
    FROM 
        title
    LEFT JOIN 
        cast_info ci ON title.id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON title.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        title.id, title.title, title.production_year
),

benchmark AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        md.total_actors,
        md.companies,
        md.roles,
        COUNT(DISTINCT mk.keyword_id) AS total_keywords
    FROM 
        actor_movies am
    JOIN 
        movie_details md ON am.movie_title = md.title AND am.production_year = md.production_year
    LEFT JOIN 
        movie_keyword mk ON md.movie_id = mk.movie_id
    GROUP BY 
        am.actor_name, am.movie_title, am.production_year, md.total_actors, md.companies, md.roles
)

SELECT 
    actor_name,
    movie_title,
    production_year,
    total_actors,
    companies,
    roles,
    total_keywords
FROM 
    benchmark
ORDER BY 
    production_year DESC, actor_name;
