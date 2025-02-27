WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel: ', m.title),
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
top_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        DENSE_RANK() OVER (PARTITION BY mh.depth ORDER BY mh.production_year DESC) AS rank
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.depth <= 5
),
cast_roles AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT ct.kind, ', ') AS roles
    FROM 
        cast_info ci
    INNER JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.movie_id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_details AS (
    SELECT 
        tm.movie_id, 
        tm.title, 
        tm.production_year, 
        cr.roles, 
        mk.keywords
    FROM 
        top_movies tm
    LEFT JOIN 
        cast_roles cr ON tm.movie_id = cr.movie_id
    LEFT JOIN 
        movie_keywords mk ON tm.movie_id = mk.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    COALESCE(mw.roles, 'No roles assigned') AS roles,
    COALESCE(mw.keywords, 'No keywords assigned') AS keywords
FROM 
    movies_with_details mw
WHERE 
    mw.production_year = (SELECT MAX(mw2.production_year) FROM movies_with_details mw2)
ORDER BY 
    mw.production_year DESC, 
    mw.title
LIMIT 10;
