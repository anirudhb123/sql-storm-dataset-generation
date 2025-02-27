WITH recursive movie_cast AS (
    SELECT 
        ca.movie_id, 
        a.name AS actor_name, 
        ca.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ca.nr_order) AS acting_order
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
), 

movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT mc.company_id::text, ', ') AS company_ids,
        COUNT(DISTINCT mk.keyword) AS total_keywords,
        MAX(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE 0 END) AS max_year,
        COALESCE(AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year END), 0) AS avg_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title
),

actor_ranked AS (
    SELECT 
        mc.movie_id,
        mc.actor_name,
        mc.acting_order,
        RANK() OVER (PARTITION BY mc.movie_id ORDER BY mc.acting_order) AS rank
    FROM 
        movie_cast mc
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_ids,
    md.total_keywords,
    ar.actor_name,
    ar.acting_order,
    ar.rank,
    CASE 
        WHEN ar.rank = 1 THEN 'Lead Actor'
        ELSE 'Supporting Actor'
    END AS actor_role
FROM 
    movie_details md
FULL OUTER JOIN 
    actor_ranked ar ON md.movie_id = ar.movie_id
WHERE 
    (md.production_year >= 2000 OR md.production_year IS NULL)
    AND (md.total_keywords = 0 OR md.company_ids IS NOT NULL)
ORDER BY 
    md.production_year DESC, 
    ar.rank ASC, 
    md.title;
