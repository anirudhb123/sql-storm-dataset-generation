WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ak.name AS aka_name,
        r.role AS person_role,
        c.nr_order
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN 
        role_type AS r ON ci.person_role_id = r.id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    WHERE 
        t.production_year >= 2000
),
keyword_stats AS (
    SELECT 
        md.movie_id,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        movie_details AS md ON md.movie_id = mk.movie_id
    GROUP BY 
        md.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.aka_name,
    md.person_role,
    md.nr_order,
    ks.keyword_count,
    ks.keyword_list,
    ci.company_names,
    ci.company_types
FROM 
    movie_details AS md
LEFT JOIN 
    keyword_stats AS ks ON md.movie_id = ks.movie_id
LEFT JOIN 
    company_info AS ci ON md.movie_id = ci.movie_id
ORDER BY 
    md.production_year DESC, 
    md.title;

