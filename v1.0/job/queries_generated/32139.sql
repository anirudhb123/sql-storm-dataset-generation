WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.title LIKE '%Part%'
    
    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
),
actors AS (
    SELECT 
        ka.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ka ON ci.person_id = ka.person_id
    GROUP BY 
        ka.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movies_with_info AS (
    SELECT 
        at.title,
        at.production_year,
        mw.keywords,
        ifi.info AS info_type
    FROM 
        aka_title AS at
    LEFT JOIN 
        movie_keywords AS mw ON at.id = mw.movie_id
    INNER JOIN 
        movie_info AS ifi ON at.id = ifi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mw.keywords,
    ar.actor_name,
    ar.movie_count
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    movies_with_info AS mw ON mh.title = mw.title
JOIN 
    actors AS ar ON mh.movie_id IN (
        SELECT 
            ci.movie_id 
        FROM 
            cast_info AS ci 
        WHERE 
            ci.person_id IN (
                SELECT 
                    ka.person_id 
                FROM 
                    aka_name AS ka
                WHERE 
                    ka.name = ar.actor_name
            )
    )
WHERE 
    mh.level = 1
ORDER BY 
    mh.production_year DESC NULLS LAST;
