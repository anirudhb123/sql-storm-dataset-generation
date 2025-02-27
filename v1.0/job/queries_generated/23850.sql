WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(NULLIF(mt.note, ''), 'No note available') AS note_content,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        m.movie_id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COALESCE(NULLIF(a.note, ''), 'No additional note') AS note_content,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        movie_hierarchy m ON ml.movie_id = m.movie_id
    WHERE 
        m.level < 3
)

, movie_roles AS (
    SELECT 
        c.movie_id,
        r.role AS actor_role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
)

, movie_keyword_counts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.note_content,
    COALESCE(mr.actor_role, 'Unknown Role') AS actor_role,
    COALESCE(mrc.role_count, 0) AS role_count,
    COALESCE(mkc.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN mh.production_year < 2000 THEN 'Classic'
        WHEN mh.production_year >= 2000 AND mh.production_year < 2010 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_roles mr ON mh.movie_id = mr.movie_id
LEFT JOIN 
    movie_keyword_counts mkc ON mh.movie_id = mkc.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        ROW_NUMBER() OVER(PARTITION BY movie_id ORDER BY role_count DESC) AS rank, 
        role_count 
     FROM movie_roles) mrc ON mh.movie_id = mrc.movie_id AND mrc.rank = 1
WHERE 
    mh.note_content IS NOT NULL
    AND (mh.level <= 1 OR mh.production_year IS NOT NULL)
ORDER BY 
    mh.production_year DESC, 
    actor_role ASC NULLS LAST;

