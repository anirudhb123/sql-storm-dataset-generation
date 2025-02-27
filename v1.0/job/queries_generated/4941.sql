WITH MovieDetails AS (
    SELECT 
        a.title,
        a.production_year,
        c.name AS company_name,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
PersonRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS total_movies,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY 
        ci.person_id
)

SELECT 
    md.title,
    md.production_year,
    md.company_name,
    md.movie_keyword,
    pr.total_movies,
    pr.roles
FROM 
    MovieDetails md
JOIN 
    PersonRoles pr ON pr.total_movies > 5
WHERE 
    md.rn = 1 
    AND md.company_name IS NOT NULL
ORDER BY 
    md.production_year DESC, 
    md.title;
