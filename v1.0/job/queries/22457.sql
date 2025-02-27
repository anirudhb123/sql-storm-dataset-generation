WITH ranked_titles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.id) AS year_rank
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
expanded_movies AS (
    SELECT 
        aka_name.person_id,
        aka_title.id AS title_id,
        aka_title.title,
        aka_title.production_year,
        aka_name.name AS actor_name
    FROM 
        aka_title
    JOIN 
        cast_info ON cast_info.movie_id = aka_title.movie_id
    JOIN 
        aka_name ON aka_name.person_id = cast_info.person_id
    WHERE 
        aka_title.production_year BETWEEN 2000 AND 2023
),
movie_statistics AS (
    SELECT 
        title_id,
        COUNT(actor_name) AS actor_count,
        STRING_AGG(actor_name, ', ') AS actor_names
    FROM 
        expanded_movies
    GROUP BY 
        title_id
),
distinct_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
combined_results AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        ms.actor_count,
        ms.actor_names,
        dk.keywords,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY ms.actor_count DESC) AS production_year_rank
    FROM 
        movie_statistics ms
    JOIN 
        ranked_titles mt ON ms.title_id = mt.title_id
    LEFT JOIN 
        distinct_keywords dk ON dk.movie_id = mt.title_id
)
SELECT 
    cr.title,
    cr.production_year,
    COALESCE(cr.actor_count, 0) AS total_actors,
    COALESCE(cr.actor_names, 'No actors listed') AS actor_list,
    COALESCE(cr.keywords, 'No keywords available') AS movie_keywords,
    cr.production_year_rank,
    DENSE_RANK() OVER (ORDER BY cr.production_year DESC, cr.actor_count DESC) AS overall_rank
FROM 
    combined_results cr
WHERE 
    cr.production_year_rank <= 5  
ORDER BY 
    cr.production_year DESC, 
    cr.actor_count DESC;