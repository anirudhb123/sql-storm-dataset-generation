WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS cast_members,
        COALESCE(GROUP_CONCAT(DISTINCT com.name ORDER BY com.name), 'No Companies') AS company_names
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name com ON mc.company_id = com.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
      AND 
        m.kind_id = 1  -- Assuming '1' represents 'movie'
    GROUP BY 
        m.id, m.title, m.production_year
),
person_details AS (
    SELECT 
        p.person_id,
        p.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        GROUP_CONCAT(DISTINCT t.kind ORDER BY t.kind) AS roles
    FROM 
        aka_name p
    LEFT JOIN 
        cast_info ci ON p.person_id = ci.person_id
    LEFT JOIN 
        role_type t ON ci.role_id = t.id
    GROUP BY 
        p.person_id, p.name
)
SELECT 
    md.movie_title,
    md.production_year,
    md.movie_keyword,
    pd.name AS cast_member_name,
    pd.movie_count AS total_movies_played,
    pd.roles AS role_types,
    md.company_names
FROM 
    movie_details md
JOIN 
    cast_info ci ON md.movie_id = ci.movie_id
JOIN 
    person_details pd ON ci.person_id = pd.person_id
ORDER BY 
    md.production_year DESC, md.movie_title;
