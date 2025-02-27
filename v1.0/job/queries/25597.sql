
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(mk.id) AS keyword_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), rich_cast_info AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        m.production_year,
        m.title
    FROM 
        ranked_movies m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.movie_id, m.production_year, m.title
), filtered_movies AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.total_cast,
        r.cast_names
    FROM 
        rich_cast_info r
    WHERE 
        r.total_cast > 5
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_cast,
    f.cast_names,
    k.keyword
FROM 
    filtered_movies f
JOIN 
    movie_keyword mk ON f.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
ORDER BY 
    f.production_year DESC, f.total_cast DESC;
