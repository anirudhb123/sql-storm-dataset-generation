WITH movie_actors AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.id AS actor_id,
        t.title AS movie_title,
        t.production_year
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
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
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
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
    ma.movie_title,
    ma.production_year,
    ma.actor_name,
    ks.keywords,
    cs.companies,
    cs.company_types
FROM 
    movie_actors ma
LEFT JOIN 
    keyword_summary ks ON ma.movie_id = ks.movie_id
LEFT JOIN 
    company_summary cs ON ma.movie_id = cs.movie_id
ORDER BY 
    ma.production_year DESC, 
    ma.movie_title, 
    ma.actor_name;
This SQL query pulls together several aspects of movie data, including the actor names, their respective movies, production years, keywords associated with those movies, and the companies involved. It utilizes common table expressions (CTEs) for processing keywords and company information while leveraging string aggregation to create a summary for each movie.
