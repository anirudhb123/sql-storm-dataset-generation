WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    GROUP BY a.id, a.title, a.production_year, k.keyword
),
actor_details AS (
    SELECT 
        n.name AS actor_name,
        c.movie_id,
        COUNT(*) AS role_count,
        MAX(CASE WHEN r.role = 'lead' THEN 1 ELSE 0 END) AS lead_role
    FROM cast_info c
    JOIN aka_name n ON c.person_id = n.person_id
    JOIN role_type r ON c.role_id = r.id
    GROUP BY n.name, c.movie_id
),
movie_info_aggregated AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Additional Info') AS additional_info,
        AVG(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS company_notes_count
    FROM aka_title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    GROUP BY m.id, m.title, mi.info
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    ad.actor_name,
    ad.role_count,
    ma.additional_info,
    CASE 
        WHEN ad.lead_role = 1 THEN 'Yes' 
        ELSE 'No' 
    END AS is_lead
FROM ranked_movies rm
JOIN actor_details ad ON rm.production_year = ad.movie_id
JOIN movie_info_aggregated ma ON rm.title = ma.title
WHERE 
    rm.rank <= 10 AND
    (ad.role_count >= 3 OR ad.lead_role = 1) AND
    (ma.additional_info NOT LIKE '%No Additional Info%' OR ma.company_notes_count > 0)
ORDER BY rm.production_year DESC, rm.title ASC;
