WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.phonetic_code,
        ARRAY[mt.id] AS movie_path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mt.phonetic_code,
        mh.movie_path || ml.linked_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mt.production_year >= 2000
),
highest_rated_movies AS (
    SELECT 
        mh.movie_id,
        AVG(r.rating) AS avg_rating
    FROM 
        movie_hierarchy mh
    LEFT JOIN 
        (SELECT movie_id, rating FROM movie_info mi WHERE mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')) r 
    ON 
        mh.movie_id = r.movie_id
    GROUP BY 
        mh.movie_id
),
actor_details AS (
    SELECT 
        ca.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ca.movie_id) AS movies_count
    FROM 
        cast_info ca
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        ca.person_id, ak.name
),
top_actors AS (
    SELECT 
        actor_name,
        movies_count,
        RANK() OVER (ORDER BY movies_count DESC) AS actor_rank
    FROM 
        actor_details
    WHERE 
        movies_count > 5
),
movies_with_actors AS (
    SELECT 
        ht.movie_id,
        ht.title,
        ht.production_year,
        COALESCE(ta.actor_name, 'Unknown Actor') AS actor_name,
        ht.avg_rating
    FROM 
        highest_rated_movies ht
    FULL OUTER JOIN 
        top_actors ta ON ht.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ak.person_id LIMIT 1)
)
SELECT 
    mw.actor_name,
    COUNT(DISTINCT mw.movie_id) AS total_movies,
    MAX(mw.avg_rating) AS highest_rating,
    STRING_AGG(DISTINCT mw.title, ', ') AS all_movie_titles
FROM 
    movies_with_actors mw
WHERE 
    mw.avg_rating IS NOT NULL
GROUP BY 
    mw.actor_name
HAVING 
    COUNT(DISTINCT mw.movie_id) > 1 AND MAX(mw.avg_rating) > 7
ORDER BY 
    highest_rating DESC, total_movies DESC;
