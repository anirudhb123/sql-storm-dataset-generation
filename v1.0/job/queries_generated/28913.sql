WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        k.keyword AS movie_keyword,
        COUNT(DISTINCT c.person_id) AS num_actors,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, a.name, a.id
),
company_data AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.num_actors,
    md.keywords_list,
    cd.companies,
    cd.company_types
FROM 
    movie_data md
LEFT JOIN 
    company_data cd ON md.actor_id = cd.movie_id
ORDER BY 
    md.production_year DESC, 
    md.num_actors DESC;
