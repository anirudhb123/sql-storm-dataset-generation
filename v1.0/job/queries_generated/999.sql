WITH movie_data AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.person_id,
        ak.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_rank
    FROM aka_title a
    JOIN cast_info ci ON a.id = ci.movie_id
    JOIN aka_name ak ON ci.person_id = ak.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE 
        a.production_year >= 2000
        AND ak.name IS NOT NULL
),
movie_keywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
actor_performance AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.actor_role,
        COALESCE(mk.keyword_list, 'No keywords') AS keywords,
        md.actor_rank
    FROM movie_data md
    LEFT JOIN movie_keywords mk ON md.movie_title = mk.movie_id
),
benchmark_results AS (
    SELECT 
        ap.movie_title,
        ap.production_year,
        ap.actor_name,
        ap.actor_role,
        ap.keywords,
        COUNT(*) OVER (PARTITION BY ap.production_year) AS movies_per_year,
        MAX(ap.actor_rank) OVER (PARTITION BY ap.movie_title) AS total_actors
    FROM actor_performance ap
)
SELECT 
    movie_title,
    production_year,
    actor_name,
    actor_role,
    keywords,
    movies_per_year,
    total_actors
FROM benchmark_results
WHERE total_actors > 2
ORDER BY production_year DESC, movie_title;
