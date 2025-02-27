WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        c.kind AS company_type,
        ak.name AS actor_name,
        rk.role AS role,
        mi.info AS movie_info
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    JOIN 
        role_type rk ON cc.person_role_id = rk.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    WHERE 
        t.production_year >= 2000
),
keyword_info AS (
    SELECT 
        kd.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword kd
    JOIN 
        keyword k ON kd.keyword_id = k.id
    GROUP BY 
        kd.movie_id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_type,
    md.actor_name,
    md.role,
    ki.keywords,
    md.movie_info
FROM 
    movie_details md
LEFT JOIN 
    keyword_info ki ON md.movie_title = (SELECT t.title FROM title t WHERE t.id = ki.movie_id)
ORDER BY 
    md.production_year DESC, md.movie_title;
