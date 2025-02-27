WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.kind AS company_type,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT a.name) AS actors
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year, c.kind
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        GROUP_CONCAT(DISTINCT pi.info) AS info
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.title,
    md.production_year,
    md.company_type,
    md.keywords,
    pd.name AS actor_name,
    pd.info
FROM 
    MovieDetails md
JOIN 
    PersonDetails pd ON md.actors LIKE CONCAT('%', pd.name, '%')
ORDER BY 
    md.production_year DESC, md.title;
