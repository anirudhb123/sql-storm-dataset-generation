
WITH movie_cast_info AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(mc.company_name, 'No Company') AS company_name
    FROM 
        aka_title m
    LEFT JOIN (
        SELECT 
            mc.movie_id,
            LISTAGG(cn.name, ', ') AS company_name
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id
        GROUP BY 
            mc.movie_id
    ) AS mc ON m.id = mc.movie_id 
    LEFT JOIN movie_keywords k ON m.id = k.movie_id
    WHERE 
        m.production_year >= 2000
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    CAST(SUM(CASE WHEN mci.role_order = 1 THEN 1 ELSE 0 END) AS INTEGER) AS lead_actor_count,
    CAST(AVG(CASE WHEN mci.nr_order IS NOT NULL THEN mci.nr_order ELSE 0 END) AS NUMERIC(5,2)) AS avg_role_order
FROM 
    movie_details md
LEFT JOIN 
    movie_cast_info mci ON md.movie_id = mci.movie_id
GROUP BY 
    md.movie_id, md.title, md.production_year, md.keywords
HAVING 
    AVG(COALESCE(mci.nr_order, 0)) < 5
ORDER BY 
    md.production_year DESC, lead_actor_count DESC;
