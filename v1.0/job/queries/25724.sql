
WITH MovieData AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
        STRING_AGG(DISTINCT co.name, ',') AS companies,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        aka_name ak ON t.id = ak.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
PersonData AS (
    SELECT 
        p.id AS person_id,
        p.name AS person_name,
        STRING_AGG(DISTINCT ci.movie_id::text, ',') AS movie_ids,
        STRING_AGG(DISTINCT rt.role, ',') AS roles
    FROM 
        name p
    JOIN 
        cast_info ci ON p.id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        p.gender = 'F'
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.aka_names,
    pd.person_id,
    pd.person_name,
    pd.movie_ids,
    pd.roles,
    md.companies,
    md.keywords
FROM 
    MovieData md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    PersonData pd ON cc.subject_id = pd.person_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC 
LIMIT 100;
