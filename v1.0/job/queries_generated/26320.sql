WITH movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title
),
person_aka AS (
    SELECT 
        p.id AS person_id, 
        p.name AS person_name, 
        STRING_AGG(a.name, ', ') AS aka_names
    FROM 
        name p
    JOIN 
        aka_name a ON p.id = a.person_id
    GROUP BY 
        p.id, p.name
),
cast_details AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        r.role,
        p.person_name,
        pa.aka_names
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        person_aka pa ON ci.person_id = pa.person_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    ORDER BY 
        ci.movie_id, ci.nr_order
)
SELECT 
    m.title,
    m.production_year,
    mk.keywords,
    cd.person_name,
    cd.aka_names,
    cd.role,
    COUNT(*) OVER (PARTITION BY m.id) AS total_cast_members
FROM 
    aka_title m
LEFT JOIN 
    movie_keywords mk ON m.id = mk.movie_id
LEFT JOIN 
    cast_details cd ON m.id = cd.movie_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, m.title;
