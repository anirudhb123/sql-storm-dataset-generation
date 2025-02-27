
WITH movie_actors AS (
    SELECT 
        ct.movie_id,
        STRING_AGG(an.name, ', ') AS actor_names,
        COUNT(DISTINCT ct.person_id) AS num_actors
    FROM 
        cast_info ct
    JOIN 
        aka_name an ON ct.person_id = an.person_id
    GROUP BY 
        ct.movie_id
),
movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        m.companies,
        mk.keywords
    FROM 
        title t
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            STRING_AGG(co.name, ' | ') AS companies
        FROM 
            movie_companies mc
        JOIN 
            company_name co ON mc.company_id = co.id
        GROUP BY 
            mc.movie_id
    ) m ON t.id = m.movie_id
    LEFT JOIN (
        SELECT 
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) mk ON t.id = mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    ma.actor_names,
    ma.num_actors,
    md.companies,
    md.keywords
FROM 
    movie_details md
JOIN 
    movie_actors ma ON md.movie_id = ma.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, 
    ma.num_actors DESC
LIMIT 50;
