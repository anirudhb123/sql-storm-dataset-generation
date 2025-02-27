WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name ak ON ak.id = at.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id
),

PersonDetails AS (
    SELECT 
        p.id AS person_id,
        p.name,
        GROUP_CONCAT(DISTINCT ci.movie_id) AS movies,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        name p
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id
)

SELECT 
    md.title,
    md.production_year,
    md.aka_names,
    md.companies,
    md.keywords,
    pd.name AS actor_name,
    pd.movies,
    pd.roles
FROM 
    MovieDetails md
LEFT JOIN 
    PersonDetails pd ON md.title_id IN (SELECT ci.movie_id FROM cast_info ci WHERE ci.person_id = pd.person_id)
WHERE 
    md.production_year >= 2000
    AND pd.roles LIKE '%actor%'
ORDER BY 
    md.production_year DESC, 
    md.title ASC;
