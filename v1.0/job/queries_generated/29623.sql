WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT CONCAT(a.name, ' (', r.role, ')') ORDER BY a.name SEPARATOR ', ') AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mi.info_type_id) AS info_count
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year, c.name, ct.kind
),
benchmark AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_names,
        keywords,
        company_name,
        company_type,
        info_count,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, title ASC) AS rank
    FROM 
        movie_data
)
SELECT 
    b.rank,
    b.title,
    b.production_year,
    b.cast_names,
    b.keywords,
    b.company_name,
    b.company_type,
    b.info_count
FROM 
    benchmark b
WHERE 
    b.info_count > 0
ORDER BY 
    b.rank
LIMIT 50;
