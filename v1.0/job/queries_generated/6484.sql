WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT a.name ORDER BY a.name) AS aka_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_title a ON t.id = a.movie_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        MAX(CASE WHEN pi.info_type_id = 1 THEN pi.info END) AS birth_date,
        MAX(CASE WHEN pi.info_type_id = 2 THEN pi.info END) AS death_date,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        p.gender = 'F'
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.keywords,
    pd.name AS actor_name,
    pd.birth_date,
    pd.death_date,
    pd.roles
FROM 
    MovieDetails md
JOIN 
    cast_info ci ON md.title_id = ci.movie_id
JOIN 
    PersonDetails pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.title;
