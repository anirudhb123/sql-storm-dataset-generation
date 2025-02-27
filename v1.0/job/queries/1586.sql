
WITH ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
casts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT an.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
movies_with_info AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.actor_names, 'No Actors') AS actor_names,
        rm.year_rank  -- Include year_rank for the final selection and ORDER BY
    FROM 
        ranked_movies rm
    LEFT JOIN 
        casts c ON rm.movie_id = c.movie_id
)
SELECT 
    mwi.title,
    mwi.production_year,
    mwi.actor_count,
    mwi.actor_names,
    CASE WHEN mwi.actor_count = 0 THEN 'N/A' ELSE CAST(mwi.actor_count AS VARCHAR) END AS actor_count_display,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mwi.movie_id) AS keyword_count,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = mwi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_info_count
FROM 
    movies_with_info mwi
WHERE 
    mwi.year_rank <= 5
ORDER BY 
    mwi.production_year DESC, 
    mwi.actor_count DESC;
