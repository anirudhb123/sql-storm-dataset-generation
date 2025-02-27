WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.name) AS company_names,
        GROUP_CONCAT(DISTINCT r.role) AS cast_roles
    FROM
        title t
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.person_role_id = r.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonDetails AS (
    SELECT 
        p.id AS person_id,
        ak.name AS aka_name,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info
    FROM 
        aka_name ak
    LEFT JOIN 
        person_info pi ON ak.person_id = pi.person_id
    GROUP BY 
        p.id, ak.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.company_names,
    md.cast_roles,
    pd.aka_name,
    pd.personal_info
FROM 
    MovieDetails md
LEFT JOIN 
    PersonDetails pd ON md.cast_roles LIKE CONCAT('%', pd.aka_name, '%')
ORDER BY 
    md.production_year DESC, 
    md.title;
