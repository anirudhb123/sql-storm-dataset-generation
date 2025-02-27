WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),

actor_info AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title t ON ci.movie_id = t.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.person_id, ak.name
),

combined_info AS (
    SELECT 
        a.person_id,
        a.name,
        a.movie_count,
        a.movies,
        mh.title AS linked_movie,
        mh.production_year,
        mh.level,
        CASE 
            WHEN a.movie_count > 10 THEN 'Prolific Actor'
            WHEN a.movie_count BETWEEN 5 AND 10 THEN 'Established Actor'
            ELSE 'New Actor'
        END AS actor_status
    FROM 
        actor_info a
    LEFT JOIN 
        movie_hierarchy mh ON a.movies LIKE '%' || mh.title || '%'
    WHERE 
        a.rn <= 10
),

final_result AS (
    SELECT 
        person_id,
        name,
        movie_count,
        movies,
        linked_movie,
        production_year,
        level,
        actor_status,
        COALESCE(linked_movie, 'No Links') AS effective_link
    FROM 
        combined_info
    WHERE 
        actor_status = 'Prolific Actor' OR (linked_movie IS NULL)
)

SELECT 
    *,
    CASE 
        WHEN level > 0 THEN 'Linked Movie Found'
        ELSE 'No Linked Movie'
    END AS linkage_status,
    CONCAT(name, ' has acted in ', movie_count, ' movies.') AS actor_summary,
    NULLIF(linked_movie, 'No Links') AS nullable_linked_movie
FROM 
    final_result
ORDER BY 
    movie_count DESC, name;
