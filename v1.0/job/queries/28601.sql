WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        ak.name AS actor_name,
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank,
        COUNT(DISTINCT cc.person_id) AS total_actors
    FROM 
        aka_title mt
    JOIN 
        cast_info cc ON mt.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    GROUP BY 
        mt.title, mt.production_year, ak.name
),
filtered_movies AS (
    SELECT 
        movie_title, 
        production_year, 
        actor_name, 
        total_actors
    FROM 
        ranked_movies
    WHERE 
        year_rank <= 5
),
movie_keywords AS (
    SELECT 
        mt.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
keyword_counts AS (
    SELECT 
        movie_title,
        COUNT(DISTINCT keyword) AS keyword_count
    FROM 
        movie_keywords
    GROUP BY 
        movie_title
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_name,
    fm.total_actors,
    kc.keyword_count
FROM 
    filtered_movies fm
LEFT JOIN 
    keyword_counts kc ON fm.movie_title = kc.movie_title
ORDER BY 
    fm.production_year DESC, 
    fm.total_actors DESC;
