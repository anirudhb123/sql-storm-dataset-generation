
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        AVG(CASE WHEN c.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS avg_actor_order,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS c ON t.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.movie_id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
), 
highest_actor_counts AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT actors) AS actor_count
    FROM 
        movie_details
    GROUP BY 
        movie_id
),
movie_company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(ct.kind) AS type_of_company
    FROM 
        movie_companies AS mc
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    hc.actor_count,
    mci.companies,
    mci.type_of_company,
    md.keyword_count
FROM 
    movie_details AS md
LEFT JOIN 
    highest_actor_counts AS hc ON md.movie_id = hc.movie_id
LEFT JOIN 
    movie_company_info AS mci ON md.movie_id = mci.movie_id
WHERE 
    (md.production_year IS NOT NULL AND md.avg_actor_order > 1) 
    OR (mci.type_of_company LIKE '%Studio%')
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC;
