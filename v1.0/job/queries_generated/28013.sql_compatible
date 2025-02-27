
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT n.name, ', ') AS full_cast_names
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name n ON c.person_id = n.person_id
    WHERE 
        m.production_year >= 2000 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    GROUP BY 
        m.id, m.title, m.production_year
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
), movie_run_time AS (
    SELECT 
        m.movie_id, 
        COALESCE(mr.info, 'Unknown') AS run_time
    FROM 
        ranked_movies m
    LEFT JOIN 
        movie_info mr ON m.movie_id = mr.movie_id 
        AND mr.info_type_id = (SELECT id FROM info_type WHERE info = 'Running Time')
), movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_cast,
    rm.full_cast_names,
    mrr.run_time,
    mk.keywords
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_run_time mrr ON rm.movie_id = mrr.movie_id
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
