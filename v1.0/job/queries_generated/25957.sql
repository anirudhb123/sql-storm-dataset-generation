WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id, 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        ARRAY_AGG(DISTINCT c.kind) AS company_kinds
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id
),
PersonDetails AS (
    SELECT 
        p.id AS person_id, 
        ak.name AS aka_name, 
        ARRAY_AGG(DISTINCT r.role) AS roles
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, ak.name
),
CombinedInfo AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.keywords,
        pd.aka_name,
        pd.roles
    FROM 
        MovieDetails md
    JOIN 
        cast_info ci ON md.movie_id = ci.movie_id
    JOIN 
        PersonDetails pd ON ci.person_id = pd.person_id
)
SELECT 
    movie_id, 
    movie_title, 
    production_year, 
    keywords,
    aka_name,
    roles
FROM 
    CombinedInfo
WHERE 
    production_year > 2000 AND 
    ARRAY_LENGTH(keywords, 1) > 2
ORDER BY 
    production_year DESC, 
    movie_title;
