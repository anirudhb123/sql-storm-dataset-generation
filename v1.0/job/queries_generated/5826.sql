WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.role_id) AS roles,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND co.country_code = 'USA'
    GROUP BY 
        t.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.roles,
    md.companies,
    md.keywords,
    COUNT(r.id) AS num_roles
FROM 
    MovieDetails md
JOIN 
    role_type r ON r.id IN (SELECT unnest(string_to_array(md.roles, ','))::integer)
GROUP BY 
    md.movie_id, md.title, md.production_year, md.roles, md.companies, md.keywords
ORDER BY 
    md.production_year DESC, md.title;
