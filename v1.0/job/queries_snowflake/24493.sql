
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        0 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    m.id AS movie_id,
    m.title AS original_title,
    COALESCE(l.linked_movie_count, 0) AS linked_movies,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(rc.role_count, 0) AS role_count,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords_list,
    ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS row_num,
    CASE 
        WHEN m.production_year IS NULL THEN 'Unknown Year'
        ELSE CAST(m.production_year AS VARCHAR)
    END AS production_year_display
FROM 
    aka_title m
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS linked_movie_count 
    FROM 
        movie_link 
    GROUP BY 
        movie_id
) l ON m.id = l.movie_id
LEFT JOIN (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
) ac ON m.id = ac.movie_id
LEFT JOIN (
    SELECT 
        ci.role_id,
        ci.movie_id,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IS NOT NULL
    GROUP BY 
        ci.role_id, ci.movie_id
) rc ON m.id = rc.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'Movie%')
    AND (
        m.title ILIKE '%adventure%' OR 
        EXISTS (
            SELECT 1 
            FROM aka_name an 
            WHERE an.id = m.id AND an.name ILIKE '%Smith%'
        )
    )
GROUP BY 
    m.id, m.title, l.linked_movie_count, ac.actor_count, rc.role_count, m.production_year
ORDER BY 
    production_year_display ASC, linked_movies DESC;
