WITH movie_titles AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
cast_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
complete_cast_info AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS total_cast,
        MAX(cc.status_id) AS highest_status
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
)
SELECT 
    mt.movie_id,
    mt.title,
    mt.production_year,
    GROUP_CONCAT(DISTINCT dt.actor_name) AS actors,
    GROUP_CONCAT(DISTINCT dt.role ORDER BY dt.role) AS roles,
    GROUP_CONCAT(DISTINCT cd.company_name) AS companies,
    GROUP_CONCAT(DISTINCT cd.company_type) AS company_types,
    cci.total_cast,
    cci.highest_status,
    STRING_AGG(DISTINCT mt.keyword, ', ') AS keywords
FROM 
    movie_titles mt
LEFT JOIN 
    cast_details dt ON mt.movie_id = dt.movie_id
LEFT JOIN 
    company_details cd ON mt.movie_id = cd.movie_id
LEFT JOIN 
    complete_cast_info cci ON mt.movie_id = cci.movie_id
GROUP BY 
    mt.movie_id, mt.title, mt.production_year, cci.total_cast, cci.highest_status
ORDER BY 
    mt.production_year DESC, mt.title;
