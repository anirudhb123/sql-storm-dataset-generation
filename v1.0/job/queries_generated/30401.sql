WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL
    UNION ALL
    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        e.kind_id,
        mh.depth + 1
    FROM 
        aka_title e
    JOIN 
        movie_hierarchy mh ON e.episode_of_id = mh.movie_id
),
cast_details AS (
    SELECT 
        ca.person_id,
        coalesce(a.name, cn.name) AS actor_name,
        MAX(ca.nr_order) AS role_order,
        COUNT(DISTINCT CASE WHEN ca.note IS NULL THEN 1 END) AS null_notes_count
    FROM 
        cast_info ca
    LEFT JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        char_name cn ON ca.person_id = cn.imdb_id
    GROUP BY 
        ca.person_id, actor_name
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id
),
highly_rated_movies AS (
    SELECT 
        m.movie_id,
        AVG(r.rating) AS average_rating
    FROM 
        complete_cast c
    JOIN 
        movie_info mi ON c.movie_id = mi.movie_id
    JOIN 
        ratings r ON r.movie_id = c.movie_id -- Assuming there's a ratings table with movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        m.movie_id
    HAVING 
        AVG(r.rating) > 8.0
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    COALESCE(kw.keyword_count, 0) AS keyword_count,
    SUM(cd.null_notes_count) AS total_null_notes,
    cd.actor_name,
    cd.role_order,
    mh.depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_keywords kw ON mh.movie_id = kw.movie_id
LEFT JOIN 
    cast_details cd ON mh.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = cd.person_id LIMIT 1)
LEFT JOIN 
    highly_rated_movies hr ON mh.movie_id = hr.movie_id
GROUP BY 
    mh.movie_id, mh.movie_title, mh.production_year, kw.keyword_count, cd.actor_name, cd.role_order, mh.depth
ORDER BY 
    mh.depth, hr.average_rating DESC NULLS LAST, keyword_count DESC;
