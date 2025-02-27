WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM title m
    WHERE m.id IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.depth + 1
    FROM movie_link ml
    JOIN title t ON ml.linked_movie_id = t.id
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_with_roles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    JOIN role_type r ON c.role_id = r.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
movie_info_extended AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ki.info, 'No Info') AS additional_info,
        mk.keyword_list
    FROM title m
    LEFT JOIN movie_info mi ON m.id = mi.movie_id
    LEFT JOIN movie_info_idx ki ON m.id = ki.movie_id AND ki.info_type_id = 1
    LEFT JOIN movie_keywords mk ON m.id = mk.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    cwr.actor_name,
    cwr.role_name,
    mie.additional_info,
    COALESCE(mie.keyword_list, 'No Keywords') AS keywords,
    mh.depth,
    CASE 
        WHEN mh.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('Feature Film', 'Documentary')) THEN 'Film'
        ELSE 'Series' 
    END AS movie_type
FROM movie_hierarchy mh
LEFT JOIN cast_with_roles cwr ON mh.movie_id = cwr.movie_id AND cwr.role_rank <= 3
LEFT JOIN movie_info_extended mie ON mh.movie_id = mie.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.production_year DESC, mh.movie_title;
