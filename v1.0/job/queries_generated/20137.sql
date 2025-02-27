WITH RecursiveCTE AS (
    SELECT 
        c.movie_id,
        c.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS rn,
        COALESCE(a.name, 'Unknown Actor') AS actor_name
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE a.name IS NOT NULL OR c.nr_order IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT cc.person_id) AS total_cast,
        SUM(CASE WHEN cc.nr_order = 1 THEN 1 ELSE 0 END) AS lead_roles,
        STRING_AGG(DISTINCT rc.actor_name, ', ') AS lead_actors
    FROM aka_title m
    JOIN complete_cast cc ON m.id = cc.movie_id
    JOIN RecursiveCTE rc ON cc.movie_id = rc.movie_id
    GROUP BY m.id, m.title, m.production_year
),
ComplicatedQuery AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.lead_roles,
        md.lead_actors,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        CASE 
            WHEN md.production_year IS NULL THEN 'Unknown Year'
            WHEN md.production_year < 2000 THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Early 21st Century'
            ELSE 'Modern Era'
        END AS era,
        (SELECT COUNT(*) 
         FROM movie_info mi 
         WHERE mi.movie_id = md.movie_id 
         AND mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%budget%')) AS budget_info_entries
    FROM MovieDetails md
    LEFT JOIN movie_keyword mk ON md.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE md.total_cast > (SELECT AVG(total_cast) FROM MovieDetails)
    ORDER BY md.production_year DESC
)
SELECT 
    cq.*,
    CASE 
        WHEN cq.lead_roles > 0 THEN 'Lead Actor Present'
        ELSE 'No Lead Actor'
    END AS lead_actor_status,
    ROW_NUMBER() OVER (ORDER BY cq.production_year DESC, cq.total_cast DESC) AS rank
FROM ComplicatedQuery cq
WHERE cq.keyword IS NOT NULL
OR cq.budget_info_entries > 0
OR cq.production_year IS NULL
LIMIT 50;
