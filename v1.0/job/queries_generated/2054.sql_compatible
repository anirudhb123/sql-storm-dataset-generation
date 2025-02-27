
WITH movie_details AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mi.info) AS info_count,
        AVG(CASE WHEN t.kind_id = 1 THEN 1 ELSE NULL END) OVER (PARTITION BY t.production_year) AS avg_feature_length
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
actor_movie_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        an.name IS NOT NULL
    GROUP BY 
        ci.person_id
),
top_actors AS (
    SELECT 
        pm.id AS person_id,
        pm.name,
        amc.movie_count
    FROM 
        aka_name pm
    JOIN 
        actor_movie_counts amc ON pm.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
    ORDER BY 
        amc.movie_count DESC
    LIMIT 10
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.company_names,
    ta.name AS top_actor_name,
    ta.movie_count,
    COALESCE(md.info_count, 0) AS info_count,
    CASE 
        WHEN md.production_year < 2000 THEN 'Classic'
        WHEN md.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    movie_details md
LEFT JOIN 
    top_actors ta ON EXISTS (SELECT 1 FROM cast_info ci WHERE ci.movie_id = md.movie_id AND ci.person_id = ta.person_id)
WHERE 
    md.avg_feature_length IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
