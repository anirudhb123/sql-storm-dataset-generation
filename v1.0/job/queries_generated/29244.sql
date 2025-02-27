WITH movie_details AS (
    SELECT 
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT c.name) AS cast_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS movie_keywords,
        GROUP_CONCAT(DISTINCT co.name) AS production_companies
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        t.id, t.title, t.production_year
),
info_collection AS (
    SELECT 
        md.title_id,
        md.movie_title,
        md.production_year,
        COUNT(DISTINCT pi.info) AS info_count,
        MAX(pi.info) AS latest_info
    FROM 
        movie_details md
    LEFT JOIN 
        movie_info mi ON md.title_id = mi.movie_id
    LEFT JOIN 
        person_info pi ON mi.movie_id = pi.person_id
    GROUP BY 
        md.title_id, md.movie_title, md.production_year
)
SELECT 
    ic.title_id,
    ic.movie_title,
    ic.production_year,
    ic.info_count,
    ic.latest_info,
    md.cast_names,
    md.movie_keywords,
    md.production_companies
FROM 
    info_collection ic
JOIN 
    movie_details md ON ic.title_id = md.title_id
ORDER BY 
    ic.production_year DESC, ic.movie_title;
