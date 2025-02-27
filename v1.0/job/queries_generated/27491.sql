WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS companies,
        GROUP_CONCAT(DISTINCT kw.keyword ORDER BY kw.keyword) AS keywords,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info ca ON cc.subject_id = ca.person_id
    GROUP BY 
        m.id
),
cast_role_breakdown AS (
    SELECT 
        ca.movie_id,
        rt.role AS role_type,
        COUNT(ca.id) AS role_count
    FROM 
        cast_info ca
    INNER JOIN 
        role_type rt ON ca.role_id = rt.id
    GROUP BY 
        ca.movie_id, rt.role
),
info_summary AS (
    SELECT 
        m.movie_id,
        COUNT(pi.id) AS personal_info_count,
        GROUP_CONCAT(DISTINCT it.info) AS info_types
    FROM 
        movie_info mi
    INNER JOIN 
        movie_details m ON mi.movie_id = m.movie_id
    LEFT JOIN 
        person_info pi ON mi.movie_id = pi.person_id
    LEFT JOIN 
        info_type it ON pi.info_type_id = it.id
    GROUP BY 
        m.movie_id
)

SELECT 
    md.movie_title,
    md.production_year,
    md.companies,
    md.keywords,
    md.cast_count,
    crb.role_type,
    crb.role_count,
    isum.personal_info_count,
    isum.info_types
FROM 
    movie_details md
LEFT JOIN 
    cast_role_breakdown crb ON md.movie_id = crb.movie_id
LEFT JOIN 
    info_summary isum ON md.movie_id = isum.movie_id
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.movie_title;
