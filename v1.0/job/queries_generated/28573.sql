WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.movie_id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        aka_name ak ON ak.person_id IN (
            SELECT 
                ci.person_id 
            FROM 
                cast_info ci 
            WHERE 
                ci.movie_id = t.movie_id
        )
    GROUP BY 
        t.id, t.title, t.production_year
),
person_details AS (
    SELECT 
        p.id AS person_id,
        p.name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        name p
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        p.id, p.name
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.company_names,
    md.keywords,
    pd.person_id,
    pd.name AS actor_name,
    pd.roles
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    person_details pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, 
    md.title ASC,
    pd.name ASC;
