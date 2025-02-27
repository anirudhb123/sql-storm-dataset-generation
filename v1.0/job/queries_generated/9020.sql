WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        c.name AS company_name,
        t.kind AS title_kind,
        k.keyword AS movie_keyword
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        kind_type t ON m.kind_id = t.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        r.role AS role_name,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_name,
    md.title_kind,
    STRING_AGG(DISTINCT pd.actor_name || ' (' || pd.role_name || ')', ', ') AS actors,
    STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords
FROM 
    MovieDetails md
LEFT JOIN 
    PersonDetails pd ON md.movie_id = pd.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.company_name, md.title_kind
ORDER BY 
    md.production_year DESC, md.title;
