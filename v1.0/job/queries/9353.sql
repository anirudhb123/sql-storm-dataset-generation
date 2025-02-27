
WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS production_companies
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        STRING_AGG(DISTINCT CONCAT(c.nr_order, '-', rt.role), ', ') AS roles
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    pd.actor_name,
    pd.roles,
    md.keywords,
    md.production_companies
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    PersonDetails pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
