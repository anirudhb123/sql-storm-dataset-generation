
WITH movie_years AS (
    SELECT 
        mt.production_year,
        mt.title,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names
    FROM 
        aka_title mt
    JOIN 
        cast_info cc ON mt.id = cc.movie_id
    JOIN 
        aka_name ak ON cc.person_id = ak.person_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.production_year, mt.title
),
ranked_movies AS (
    SELECT 
        my.production_year,
        my.title,
        my.actor_count,
        my.actor_names,
        RANK() OVER (PARTITION BY my.production_year ORDER BY my.actor_count DESC) AS rank
    FROM 
        movie_years my
),
recent_movies AS (
    SELECT 
        rm.*
    FROM 
        ranked_movies rm
    WHERE 
        rm.rank <= 3
)

SELECT 
    rm.production_year,
    rm.title,
    rm.actor_count,
    rm.actor_names,
    (SELECT COUNT(*)
     FROM complete_cast cc
     WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)
       AND cc.status_id IS NULL) AS complete_cast_nulls
FROM 
    recent_movies rm
LEFT JOIN 
    movie_info mi ON (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1) = mi.movie_id
WHERE 
    mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%Award%')
    OR EXISTS (SELECT 1 FROM movie_keyword mk JOIN keyword k ON mk.keyword_id = k.id WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1) AND k.keyword = 'Best Picture')
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
