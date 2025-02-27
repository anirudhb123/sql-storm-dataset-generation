WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        m2.title AS linked_movie_title
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN movie_link ml ON m.id = ml.movie_id
    LEFT JOIN aka_title m2 ON ml.linked_movie_id = m2.id
    WHERE 
        m.production_year > 2000
    UNION ALL
    SELECT 
        a.id,
        a.title,
        a.production_year,
        COALESCE(b.keyword, 'No Keywords') AS keyword,
        NULL AS linked_movie_title
    FROM 
        aka_title a
    JOIN movie_keyword b ON a.id = b.movie_id
    WHERE 
        a.production_year < 2000
),
cast_with_ranks AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
),
leading_actors AS (
    SELECT 
        movie_id,
        STRING_AGG(actor_name, ', ') AS leading_actors_list,
        MAX(role_rank) AS highest_role_rank
    FROM 
        cast_with_ranks 
    WHERE 
        role_rank <= 3
    GROUP BY 
        movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.keyword,
    la.leading_actors_list,
    la.highest_role_rank
FROM 
    movie_hierarchy mh
LEFT JOIN leading_actors la ON mh.movie_id = la.movie_id
WHERE 
    mh.keyword IS NOT NULL
ORDER BY 
    mh.production_year DESC, 
    la.highest_role_rank ASC;

