
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
cast_details AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
movie_keyword_cte AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) OVER (PARTITION BY mk.movie_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.rank_by_title,
    m.total_movies,
    COALESCE(cd.distinct_cast_count, 0) AS distinct_cast_count,
    COALESCE(cd.actors_names, 'No cast available') AS actors_names,
    COALESCE(mkc.keyword, 'No keywords') AS keywords,
    mkc.keyword_count
FROM 
    ranked_movies m
LEFT JOIN 
    cast_details cd ON m.movie_id = cd.movie_id
LEFT JOIN 
    movie_keyword_cte mkc ON m.movie_id = mkc.movie_id
WHERE 
    m.rank_by_title <= 5 
    AND (m.production_year < 2000 OR mkc.keyword_count IS NOT NULL)
ORDER BY 
    m.production_year DESC, 
    m.rank_by_title ASC;
