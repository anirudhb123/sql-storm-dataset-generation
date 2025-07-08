
WITH ranked_movies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        a.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
top_ranked AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        kind_id,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tr.movie_id,
    tr.movie_title,
    tr.production_year,
    tr.kind_id,
    tr.cast_count,
    tr.aka_names,
    tr.keywords
FROM 
    top_ranked tr
WHERE 
    tr.rank <= 5
ORDER BY 
    tr.production_year DESC, tr.cast_count DESC;
