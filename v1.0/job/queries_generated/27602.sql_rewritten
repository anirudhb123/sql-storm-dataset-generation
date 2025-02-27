WITH movie_with_actors AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        a.name AS actor_name,
        a.id AS actor_id
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2020
),
actor_keywords AS (
    SELECT 
        mw.movie_id,
        mw.movie_title,
        mw.actor_name,
        k.keyword
    FROM 
        movie_with_actors mw
    JOIN 
        movie_keyword mk ON mw.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
movie_info_summary AS (
    SELECT 
        mw.movie_id,
        mw.movie_title,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        movie_with_actors mw
    JOIN 
        cast_info ci ON mw.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mw.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mw.movie_id, mw.movie_title
),
final_summary AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.keywords,
        m.actor_count,
        (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = m.movie_id) AS info_count
    FROM 
        movie_info_summary m
)
SELECT 
    fs.movie_id,
    fs.movie_title,
    fs.keywords,
    fs.actor_count,
    fs.info_count
FROM 
    final_summary fs
WHERE 
    fs.actor_count > 5
ORDER BY 
    fs.actor_count DESC, fs.movie_title ASC;