WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        0 AS level
    FROM 
        aka_title AS m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        mc.linked_movie_id,
        lt.title,
        lt.production_year,
        lt.kind_id,
        mh.level + 1
    FROM 
        movie_link AS mc
    JOIN 
        aka_title AS lt ON mc.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy AS mh ON mc.movie_id = mh.movie_id
),
actor_casts AS (
    SELECT 
        ai.name,
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ai ON ci.person_id = ai.person_id
    WHERE 
        ai.name IS NOT NULL
    GROUP BY 
        ai.name, ci.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        SUM(ac.actor_count) OVER (PARTITION BY mh.movie_id) AS total_actors,
        DENSE_RANK() OVER (PARTITION BY mh.production_year ORDER BY SUM(ac.actor_count) DESC) AS year_rank
    FROM 
        movie_hierarchy AS mh
    LEFT JOIN 
        actor_casts AS ac ON mh.movie_id = ac.movie_id
    WHERE 
        mh.level = 0
),
company_info AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ri.company_count, 0) AS production_companies,
    rm.total_actors,
    CASE 
        WHEN rm.total_actors > 50 THEN 'Blockbuster' 
        WHEN rm.total_actors BETWEEN 21 AND 50 THEN 'Hit'
        ELSE 'Indie' 
    END AS movie_category,
    STRING_AGG(DISTINCT a.name, ', ') AS prominent_actors
FROM 
    ranked_movies AS rm
LEFT JOIN 
    company_info AS ri ON rm.movie_id = ri.movie_id
LEFT JOIN 
    cast_info AS ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name AS a ON ci.person_id = a.person_id
WHERE 
    rm.year_rank <= 10 
    AND rm.total_actors IS NOT NULL
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ri.company_count, rm.total_actors
ORDER BY 
    rm.production_year DESC, rm.total_actors DESC
LIMIT 100;

