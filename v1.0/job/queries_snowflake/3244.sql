WITH ranked_titles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
cast_members AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count,
        MAX(CASE WHEN a.name IS NOT NULL THEN 1 ELSE 0 END) AS has_aka_name
    FROM 
        cast_info ci
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_details AS (
    SELECT 
        t.title, 
        t.production_year, 
        cc.kind AS company_category,
        cm.actor_count,
        CASE 
            WHEN cm.has_aka_name = 1 THEN 'Yes' 
            ELSE 'No' 
        END AS has_aka_name
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        comp_cast_type cc ON mc.company_type_id = cc.id
    JOIN 
        cast_members cm ON t.id = cm.movie_id
    WHERE 
        t.production_year IS NOT NULL
        AND t.production_year > 2000
)
SELECT 
    md.title, 
    md.production_year, 
    md.company_category,
    md.actor_count,
    md.has_aka_name
FROM 
    movie_details md
WHERE 
    (md.actor_count > 5 OR md.has_aka_name = 'Yes')
ORDER BY 
    md.production_year DESC, 
    md.actor_count DESC
LIMIT 10;
