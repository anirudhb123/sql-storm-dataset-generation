WITH movie_data AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names,
        STRING_AGG(DISTINCT CONCAT(p.first_name, ' ', p.last_name), ', ') AS cast_names,
        COUNT(cast.id) AS total_cast,
        COUNT(DISTINCT co.name) AS total_companies,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        COUNT(DISTINCT mi.info) AS unique_movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info cast ON cc.subject_id = cast.person_id
    LEFT JOIN 
        aka_name ak ON cast.person_id = ak.person_id
    LEFT JOIN 
        person_info pi ON cast.person_id = pi.person_id
    LEFT JOIN 
        role_type r ON cast.role_id = r.id
    LEFT JOIN (
        SELECT id, name AS first_name, 
        (SELECT name FROM name WHERE id = cp.id) AS last_name 
        FROM name cp
    ) p ON cast.person_id = p.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_names,
    md.keywords,
    md.company_names,
    md.cast_names,
    md.total_cast,
    md.total_companies,
    md.roles,
    md.unique_movie_info
FROM 
    movie_data md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, 
    md.total_cast DESC;
