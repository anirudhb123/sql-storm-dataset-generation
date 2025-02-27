WITH movie_details AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY ci.nr_order) AS actor_order
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
company_details AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COALESCE(SUM(CASE WHEN c.type_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS has_contracts
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        complete_cast c ON mc.movie_id = c.movie_id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)
SELECT 
    md.movie_title,
    md.production_year,
    STRING_AGG(md.actor_name, ', ') AS actors,
    cd.company_name,
    cd.company_type,
    cd.has_contracts,
    md.actor_order
FROM 
    movie_details md
LEFT JOIN 
    company_details cd ON md.movie_title = cd.movie_id
WHERE 
    md.production_year >= 2000 AND 
    (cd.has_contracts > 0 OR cd.company_name IS NULL)
GROUP BY 
    md.movie_title, md.production_year, cd.company_name, cd.company_type, md.actor_order
ORDER BY 
    md.production_year DESC, md.movie_title;
