WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        COUNT(mc.id) AS company_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.company_count
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.production_year < mt.production_year
),

top_movies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.company_count,
        RANK() OVER (ORDER BY mh.production_year DESC, mh.company_count DESC) AS rank
    FROM 
        movie_hierarchy mh
    WHERE 
        mh.company_count > 0
),

actor_info AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS total_movies
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.id, ak.name
),

filtered_actor_info AS (
    SELECT 
        actor_name,
        total_movies
    FROM 
        actor_info
    WHERE 
        total_movies > (
            SELECT 
                AVG(total_movies) 
            FROM 
                actor_info
        )
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.company_count,
    fak.actor_name,
    fak.total_movies
FROM 
    top_movies tm
LEFT JOIN 
    filtered_actor_info fak ON fak.total_movies > (
        SELECT 
            AVG(total_movies) 
        FROM 
            actor_info
    )
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.company_count DESC;
