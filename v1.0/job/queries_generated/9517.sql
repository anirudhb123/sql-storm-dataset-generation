WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        r.role AS role_name,
        c.nr_order
    FROM 
        title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
),
keyword_details AS (
    SELECT 
        t.title AS movie_title,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
company_details AS (
    SELECT 
        t.title AS movie_title,
        GROUP_CONCAT(cn.name) AS companies
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        t.id
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.role_name,
    kd.keywords,
    cd.companies
FROM 
    movie_details md
JOIN 
    keyword_details kd ON md.movie_title = kd.movie_title
JOIN 
    company_details cd ON md.movie_title = cd.movie_title
ORDER BY 
    md.production_year DESC, md.movie_title;
