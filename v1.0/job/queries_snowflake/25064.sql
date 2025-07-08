
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT g.keyword, ', ') WITHIN GROUP (ORDER BY g.keyword) AS genres
    FROM 
        title m
    LEFT JOIN 
        complete_cast cc ON m.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword g ON mk.keyword_id = g.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
), 
ranked_movies_with_type AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actors,
        rm.genres,
        kt.kind AS kind
    FROM 
        ranked_movies rm
    JOIN 
        kind_type kt ON rm.movie_id = kt.id
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_count,
    r.actors,
    r.genres,
    r.kind,
    RANK() OVER (ORDER BY r.cast_count DESC) AS rank_by_cast
FROM 
    ranked_movies_with_type r
WHERE 
    r.cast_count > 1
ORDER BY 
    rank_by_cast;
