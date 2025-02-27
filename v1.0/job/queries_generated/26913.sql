WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT co.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        aka_name AS ak ON t.id = ak.movie_id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'documentary'))
    GROUP BY 
        t.id, t.title, t.production_year
),

PersonData AS (
    SELECT 
        c.person_id,
        GROUP_CONCAT(DISTINCT n.name) AS person_names,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        cast_info AS c
    LEFT JOIN 
        name AS n ON c.person_id = n.imdb_id
    LEFT JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.person_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    pd.person_names,
    pd.roles,
    md.companies,
    md.keywords
FROM 
    MovieData AS md
LEFT JOIN 
    complete_cast AS cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    PersonData AS pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.title;
