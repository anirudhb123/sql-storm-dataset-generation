WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
movie_info_summary AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        rm.actor_count,
        COALESCE(mi.info, 'No Info Available') AS movie_additional_info
    FROM 
        ranked_movies AS rm
    LEFT JOIN 
        movie_info AS mi ON rm.movie_id = mi.movie_id AND mi.info_type_id IN (
            SELECT id FROM info_type WHERE info LIKE 'Genre%'
        )
)
SELECT 
    m.title,
    m.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    m.actor_count,
    m.movie_additional_info
FROM 
    movie_info_summary AS m
LEFT JOIN 
    movie_keyword AS mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.actor_count DESC, 
    m.production_year DESC
LIMIT 50;
