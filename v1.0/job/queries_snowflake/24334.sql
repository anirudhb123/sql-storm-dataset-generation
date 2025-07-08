
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS title_rank
    FROM title t
    WHERE t.production_year IS NOT NULL
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.role_id) AS role_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM cast_info ci
    JOIN aka_name ak ON ci.person_id = ak.person_id
    GROUP BY ci.movie_id
),
company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        LISTAGG(DISTINCT cq.kind, ', ') WITHIN GROUP (ORDER BY cq.kind) AS company_types
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type cq ON mc.company_type_id = cq.id
    GROUP BY mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.role_count,
    cd.actor_names,
    ci.company_count,
    ci.company_types,
    CASE 
        WHEN rt.production_year < 2000 THEN 'Classic'
        WHEN rt.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era_label,
    COALESCE(rd.info, 'No additional info') AS additional_info
FROM ranked_titles rt
LEFT JOIN cast_details cd ON rt.title_id = cd.movie_id
LEFT JOIN company_info ci ON rt.title_id = ci.movie_id
LEFT JOIN LATERAL (
    SELECT mi.info FROM movie_info mi 
    WHERE mi.movie_id = rt.title_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'box office'
    ) LIMIT 1
) rd ON true
WHERE rt.title_rank <= 10
ORDER BY rt.production_year DESC, cd.role_count DESC
LIMIT 50;
