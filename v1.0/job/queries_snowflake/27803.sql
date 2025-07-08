
WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    JOIN
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE
        a.production_year IS NOT NULL
),

cast_details AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT n.name, ', ') WITHIN GROUP (ORDER BY n.name) AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),

company_roles AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        LISTAGG(DISTINCT co.name, ', ') WITHIN GROUP (ORDER BY co.name) AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, ct.kind
)

SELECT 
    rt.title,
    rt.production_year,
    rt.keyword,
    cd.cast_count,
    cd.cast_names,
    cr.company_count,
    cr.company_names,
    cr.company_type
FROM 
    ranked_titles rt
LEFT JOIN 
    cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    company_roles cr ON rt.title_id = cr.movie_id
WHERE 
    rt.rn <= 10 
ORDER BY 
    rt.production_year DESC, rt.title;
