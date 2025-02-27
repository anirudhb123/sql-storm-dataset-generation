WITH ranked_movies AS (
    SELECT
        mt.title,
        mt.production_year,
        COUNT(cc.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(cc.id) DESC) as year_rank
    FROM
        aka_title mt
    LEFT JOIN cast_info cc ON mt.id = cc.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
keyword_aggregates AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword, ', ') AS keyword_list,
        COUNT(DISTINCT mk.keyword_id) AS unique_keyword_count
    FROM
        movie_keyword mk 
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
title_with_cast AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(ka.name, 'Unknown') AS first_actor,
        r.cast_count,
        kw.keyword_list,
        kw.unique_keyword_count
    FROM
        aka_title a
    LEFT JOIN (
        SELECT 
            movie_id, 
            MIN(person_id) AS first_actor_id 
        FROM 
            cast_info 
        GROUP BY movie_id
    ) AS first_actors ON a.id = first_actors.movie_id
    LEFT JOIN aka_name ka ON first_actors.first_actor_id = ka.person_id
    JOIN ranked_movies r ON a.title = r.title AND a.production_year = r.production_year
    LEFT JOIN keyword_aggregates kw ON a.id = kw.movie_id
    WHERE 
        r.year_rank <= 5 OR 
        (kw.unique_keyword_count IS NULL AND a.production_year > 2010)
)

SELECT 
    title,
    production_year,
    first_actor,
    cast_count,
    keyword_list,
    unique_keyword_count
FROM 
    title_with_cast
WHERE 
    (unique_keyword_count > 3 OR cast_count > 10)
ORDER BY 
    production_year DESC, 
    title;
