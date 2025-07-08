WITH RECURSIVE movie_chain AS (
    SELECT 
        mt.movie_id,
        mt.title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        at.title,
        mc.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.movie_id
    JOIN 
        movie_chain mc ON ml.movie_id = mc.movie_id
    WHERE 
        mc.level < 5
),
movie_ratings AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.id) AS cast_count,
        AVG(CASE 
            WHEN p.info LIKE '%Oscar%' THEN 1
            ELSE 0
        END) AS oscar_awarded
    FROM 
        title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        person_info p ON c.person_id = p.person_id
    GROUP BY 
        m.id
),
ranked_movies AS (
    SELECT 
        mc.movie_id,
        mc.title,
        mr.cast_count,
        mr.oscar_awarded,
        RANK() OVER (ORDER BY mr.cast_count DESC, mr.oscar_awarded DESC) AS rank
    FROM 
        movie_chain mc
    LEFT JOIN 
        movie_ratings mr ON mc.movie_id = mr.movie_id
),
final_result AS (
    SELECT 
        rm.rank,
        rm.title,
        COALESCE(mr.cast_count, 0) AS cast_count,
        COALESCE(mr.oscar_awarded, 0) AS oscar_awarded
    FROM 
        ranked_movies rm
    LEFT JOIN 
        movie_ratings mr ON rm.movie_id = mr.movie_id
    WHERE 
        rm.rank <= 10
)

SELECT 
    fr.rank,
    fr.title,
    fr.cast_count,
    fr.oscar_awarded,
    CASE 
        WHEN fr.oscar_awarded > 0 THEN 'Awarded'
        ELSE 'Not Awarded'
    END AS award_status
FROM 
    final_result fr
ORDER BY 
    fr.rank;