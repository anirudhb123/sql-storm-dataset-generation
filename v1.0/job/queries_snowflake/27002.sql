
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aka_names
    FROM 
        ranked_movies
    WHERE 
        rank <= 10
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.cast_count,
    COALESCE(fm.aka_names, 'N/A') AS aka_names,
    COALESCE(k.keywords, 'No keywords available') AS keywords
FROM 
    filtered_movies fm
LEFT JOIN (
    SELECT 
        t.id AS movie_id,
        LISTAGG(kw.keyword, ', ') WITHIN GROUP (ORDER BY kw.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    GROUP BY 
        t.id
) k ON fm.movie_id = k.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.cast_count DESC;
