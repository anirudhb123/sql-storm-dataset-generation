WITH movie_title_info AS (
    SELECT 
        t.id AS movie_id,
        t.title AS title,
        t.production_year,
        GROUP_CONCAT(k.keyword) AS keywords,
        GROUP_CONCAT(DISTINCT c.kind) AS company_types
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
person_name_info AS (
    SELECT 
        p.person_id,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        p.gender
    FROM 
        name p
    LEFT JOIN 
        aka_name ak ON p.id = ak.person_id
    GROUP BY 
        p.person_id, p.gender
)
SELECT 
    mti.title,
    mti.production_year,
    mti.keywords,
    mti.company_types,
    c.total_cast,
    c.roles,
    p.aka_names,
    p.gender
FROM 
    movie_title_info mti
JOIN 
    cast_info_summary c ON mti.movie_id = c.movie_id
LEFT JOIN 
    cast_info ci ON c.movie_id = ci.movie_id 
LEFT JOIN 
    person_name_info p ON ci.person_id = p.person_id
ORDER BY 
    mti.production_year DESC, mti.title;
