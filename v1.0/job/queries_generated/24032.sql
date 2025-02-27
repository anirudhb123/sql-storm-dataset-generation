WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mc.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link mc
    JOIN 
        aka_title m ON mc.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON mc.movie_id = mh.movie_id
),
actor_details AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        INITCAP(a.name) AS formatted_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY a.name) AS row_num
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
        AND LENGTH(a.name) > 2
),
movies_with_additional_info AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        COALESCE(AVG(a.actor_count), 0) AS avg_actors,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        movie_hierarchy m
    LEFT JOIN 
        actor_details a ON m.movie_id = a.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id,
        m.movie_title,
        m.production_year
),
final_output AS (
    SELECT 
        m.movie_title,
        m.production_year,
        m.avg_actors,
        m.keywords,
        CASE 
            WHEN m.production_year < 2000 THEN 'Classic'
            WHEN m.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
            ELSE 'Recent'
        END AS era
    FROM 
        movies_with_additional_info m
    WHERE 
        m.production_year IS NOT NULL
)
SELECT 
    fo.movie_title,
    fo.production_year,
    fo.avg_actors,
    fo.keywords,
    fo.era
FROM 
    final_output fo
WHERE 
    fo.avg_actors > (SELECT AVG(avg_actors) FROM movies_with_additional_info)
ORDER BY 
    fo.production_year DESC,
    fo.avg_actors DESC;
