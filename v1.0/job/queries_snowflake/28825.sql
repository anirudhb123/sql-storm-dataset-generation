
WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT CONCAT(a.name, ' (', c.nr_order, ')'), ', ') WITHIN GROUP (ORDER BY a.name) AS full_cast,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year > 2000
        AND c.nr_order IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
filtered_movies AS (
    SELECT 
        rm.*,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rm.cast_count DESC) AS rank
    FROM 
        ranked_movies rm
    WHERE 
        rm.cast_count > 5
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    fm.full_cast,
    fm.keywords
FROM 
    filtered_movies fm
WHERE 
    fm.rank <= 10
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;
