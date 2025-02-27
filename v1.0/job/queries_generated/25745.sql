WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        GROUP_CONCAT(DISTINCT ak.name) AS aka_names,
        GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        (SELECT DISTINCT name, movie_id FROM aka_name) AS ak ON t.movie_id = ak.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
cast_info_details AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS cast_count,
        GROUP_CONCAT(DISTINCT r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    ct.kind AS movie_kind,
    ci.cast_count,
    ci.roles,
    md.aka_names,
    md.keywords
FROM 
    movie_details md
JOIN 
    kind_type ct ON md.kind_id = ct.id
LEFT JOIN 
    cast_info_details ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;
