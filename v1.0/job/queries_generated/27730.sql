WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS role_ids,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT co.name) AS companies 
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        company_name co ON ci.movie_id = co.imdb_id
    GROUP BY 
        t.id
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
        p.id
)

SELECT 
    md.title,
    md.production_year,
    pd.name AS lead_actor_name,
    pd.info AS actor_info,
    md.keywords,
    md.companies
FROM 
    MovieDetails md
JOIN 
    complete_cast cc ON md.title_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
WHERE 
    md.production_year = 2020 
    AND pd.info LIKE '%Oscar%'
ORDER BY 
    md.title;
