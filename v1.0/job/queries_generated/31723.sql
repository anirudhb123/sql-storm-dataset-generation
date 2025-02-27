WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        0 AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 AND 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        linked.linked_movie_id,
        linked_movie.title,
        linked_movie.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        movie_link linked
    JOIN 
        aka_title linked_movie ON linked.linked_movie_id = linked_movie.id
    JOIN 
        movie_hierarchy mh ON linked.movie_id = mh.movie_id
    WHERE 
        linked_movie.production_year >= 2000
),
avg_role_count AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS role_count
    FROM 
        cast_info c 
    GROUP BY 
        c.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ar.role_count, 0) AS role_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(ar.role_count, 0) DESC) AS rank
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        avg_role_count ar ON mh.movie_id = ar.movie_id
)
SELECT 
    t.title,
    t.production_year,
    t.role_count,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
FROM 
    top_movies t
LEFT JOIN 
    cast_info c ON t.movie_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.rank <= 10
GROUP BY 
    t.movie_id, t.title, t.production_year, t.role_count
ORDER BY 
    t.role_count DESC, t.production_year ASC;
