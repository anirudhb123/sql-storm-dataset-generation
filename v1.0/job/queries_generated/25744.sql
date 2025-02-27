WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonRoles AS (
    SELECT 
        ci.movie_id,
        GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
        GROUP_CONCAT(DISTINCT n.name ORDER BY n.name) AS actors
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        aka_name n ON ci.person_id = n.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keywords,
    pr.roles,
    pr.actors
FROM 
    MovieDetails md
LEFT JOIN 
    PersonRoles pr ON md.movie_id = pr.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title;
