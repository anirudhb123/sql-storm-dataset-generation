WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS level,
        CAST(m.title AS VARCHAR(255)) AS path
    FROM 
        aka_title AS m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.movie_id, 
        e.title,
        h.level + 1,
        CAST(h.path || ' > ' || e.title AS VARCHAR(255))
    FROM 
        aka_title AS e
    INNER JOIN 
        movie_hierarchy AS h ON e.episode_of_id = h.movie_id
),
keyword_counts AS (
    SELECT
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword AS mk
    INNER JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_detail AS (
    SELECT 
        a.title,
        m.production_year,
        cc.role,
        co.name AS company_name,
        k.keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY cc.nr_order) AS actor_order
    FROM 
        aka_title AS m
    LEFT JOIN 
        cast_info AS cc ON m.id = cc.movie_id
    LEFT JOIN 
        role_type AS r ON cc.role_id = r.id
    LEFT JOIN 
        movie_companies AS mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name AS co ON mc.company_id = co.id
    LEFT JOIN 
        keyword_counts AS k ON m.id = k.movie_id
    WHERE 
        m.production_year IS NOT NULL
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.company_name, 'Unknown') AS production_company,
    COUNT(DISTINCT CASE WHEN md.actor_order <= 5 THEN cc.person_id END) AS top_5_actors,
    STRING_AGG(DISTINCT CASE WHEN md.actor_order <= 5 THEN p.name END, ', ') AS top_5_actor_names,
    COALESCE(md.keyword_count, 0) AS keyword_count
FROM 
    movie_detail AS md
LEFT JOIN 
    cast_info AS cc ON md.movie_id = cc.movie_id
LEFT JOIN 
    aka_name AS p ON cc.person_id = p.person_id
GROUP BY 
    md.title, md.production_year, md.company_name, md.keyword_count
ORDER BY 
    md.production_year DESC,
    md.title
LIMIT 100;
