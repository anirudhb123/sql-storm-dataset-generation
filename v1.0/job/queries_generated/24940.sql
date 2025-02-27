WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        CONCAT('Sequel of: ', m.title) AS title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
ranked_movies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.depth DESC) AS rn
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.depth <= 3
),
popular_movies AS (
    SELECT 
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        k.keyword
    HAVING 
        COUNT(*) > 1
),
actor_movie_count AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    GROUP BY 
        ai.person_id
),
movies_with_people AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        r.role,
        COALESCE(ac.movie_count, 0) AS actor_count,
        COALESCE(pm.keyword_count, 0) AS keyword_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        actor_movie_count ac ON ac.person_id = ci.person_id
    LEFT JOIN 
        popular_movies pm ON pm.keyword_count = rm.depth
)
SELECT 
    mw.title,
    mw.production_year,
    mw.actor_count,
    mw.keyword_count,
    CASE 
        WHEN mw.actor_count > 5 THEN 'Popular'
        WHEN mw.actor_count BETWEEN 2 AND 5 THEN 'Moderate'
        ELSE 'Niche'
    END AS movie_fame
FROM 
    movies_with_people mw
WHERE 
    mw.keyword_count IS NOT NULL
    AND (mw.production_year > 2000 OR mw.actor_count BETWEEN 4 AND 10)
ORDER BY 
    mw.production_year DESC, mw.actor_count DESC
FETCH FIRST 10 ROWS ONLY;
