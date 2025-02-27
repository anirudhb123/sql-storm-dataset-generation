WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, c.name
),
CastDetails AS (
    SELECT 
        t.title AS movie_title,
        a.name AS actor_name,
        r.role AS role,
        ci.nr_order AS acting_order
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.aka_names,
    md.keywords,
    cd.actor_name,
    cd.role,
    cd.acting_order
FROM 
    MovieDetails md
LEFT JOIN 
    CastDetails cd ON md.movie_title = cd.movie_title
ORDER BY 
    md.production_year DESC, md.movie_title, cd.acting_order;
