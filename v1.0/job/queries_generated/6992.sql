WITH MovieDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.kind_id) AS cast_kinds,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
        c2.name AS company_name,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        comp_cast_type c ON ci.person_role_id = c.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c2 ON mc.company_id = c2.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, c2.name, ct.kind
),
PersonDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name,
        p.gender,
        GROUP_CONCAT(DISTINCT pi.info) AS personal_info
    FROM 
        aka_name a
    JOIN 
        name n ON a.person_id = n.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        n.gender = 'F'
    GROUP BY 
        a.id, n.gender
)
SELECT 
    md.title,
    md.production_year,
    pd.name AS actress_name,
    pd.personal_info,
    md.cast_kinds,
    md.movie_keywords,
    md.company_name,
    md.company_type
FROM 
    MovieDetails md
JOIN 
    PersonDetails pd ON md.cast_kinds LIKE '%' || pd.aka_id || '%'
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, pd.name;
