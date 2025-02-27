WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.name AS company_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    GROUP BY 
        t.id, c.name, t.production_year
    ORDER BY 
        t.production_year DESC
),
person_data AS (
    SELECT 
        p.name AS person_name,
        p.gender,
        pi.info AS biography,
        STRING_AGG(DISTINCT rl.role, ', ') AS roles
    FROM 
        name p
    LEFT JOIN 
        person_info pi ON p.id = pi.person_id
    LEFT JOIN 
        cast_info ci ON p.id = ci.person_id
    LEFT JOIN 
        role_type rl ON ci.role_id = rl.id
    GROUP BY 
        p.id, p.name, p.gender, pi.info
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    md.keywords,
    md.aka_names,
    pd.person_name,
    pd.gender,
    pd.biography,
    pd.roles
FROM 
    movie_data md
JOIN 
    complete_cast cc ON md.movie_id = cc.movie_id
JOIN 
    person_data pd ON cc.subject_id = pd.id
WHERE 
    md.production_year >= 2000
    AND (
        pd.roles LIKE '%Director%'
        OR pd.roles LIKE '%Actor%'
        OR pd.roles LIKE '%Producer%'
    )
ORDER BY 
    md.production_year DESC, pd.person_name;
