
WITH RECURSIVE ranked_movies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mci.company_type_id DESC) AS rank_per_year
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS cast_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
movie_cast_details AS (
    SELECT 
        rm.movie_id, 
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.cast_rank
    FROM 
        ranked_movies rm
    LEFT JOIN 
        cast_details cd ON rm.movie_id = cd.movie_id
    WHERE 
        rm.rank_per_year <= 5
)
SELECT 
    mc.movie_id,
    mc.title, 
    mc.production_year,
    LISTAGG(mc.actor_name, ', ') WITHIN GROUP (ORDER BY mc.actor_name) AS actors,
    COUNT(*) FILTER (WHERE mc.cast_rank IS NOT NULL) AS total_cast,
    SUM(CASE WHEN mc.cast_rank IS NULL THEN 1 ELSE 0 END) AS missing_actors,
    MAX(mc.production_year) - MIN(mc.production_year) AS production_span
FROM 
    movie_cast_details mc
GROUP BY 
    mc.movie_id, mc.title, mc.production_year
HAVING 
    COUNT(DISTINCT mc.actor_name) > 0
ORDER BY 
    mc.production_year DESC, 
    total_cast DESC
LIMIT 10;
