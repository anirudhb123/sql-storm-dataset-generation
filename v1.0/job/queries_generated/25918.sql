WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS aliases,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        m.id
),
person_info_details AS (
    SELECT 
        pi.person_id,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info,
        GROUP_CONCAT(DISTINCT rt.role) AS roles
    FROM 
        person_info pi
    LEFT JOIN 
        cast_info ci ON pi.person_id = ci.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        pi.person_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aliases,
    md.company_names,
    md.keywords,
    pid.personal_info,
    pid.roles
FROM 
    movie_details md
LEFT JOIN 
    person_info_details pid ON pid.person_id IN (
        SELECT DISTINCT ci.person_id
        FROM cast_info ci
        WHERE ci.movie_id = md.movie_id
    )
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.title;
