WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title mt
    JOIN 
        cast_info ci ON mt.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023
        AND mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
), 
movie_keywords AS (
    SELECT 
        mm.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mm
    JOIN 
        keyword k ON mm.keyword_id = k.id
    GROUP BY 
        mm.movie_id
), 
movie_info_enriched AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rk.actor_name,
        mk.keywords,
        COUNT(DISTINCT ci.id) OVER (PARTITION BY rm.production_year) AS total_movies_by_year
    FROM 
        ranked_movies rk
    JOIN 
        movie_companies mc ON rk.actor_id = mc.company_id
    JOIN 
        movie_keywords mk ON mc.movie_id = mk.movie_id
)

SELECT 
    movie_title,
    production_year,
    actor_name,
    keywords,
    total_movies_by_year
FROM 
    movie_info_enriched
WHERE 
    actor_rank <= 3
ORDER BY 
    production_year DESC, 
    movie_title;

This SQL query benchmarks string processing capabilities by creating a common table expression (CTE) that ranks actors in movies from the years 2000 to 2023, enriches movie data with keywords, and applies transformations such as aggregations (using `STRING_AGG` for keywords). It ultimately returns the top three actors per movie for a concise overview, each along with associated keywords and the total number of movies produced in that year. The final sorting allows for straightforward comparisons across the recent film landscape.
