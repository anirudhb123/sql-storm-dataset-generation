
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        MAX(t.production_year) AS release_year,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023 
    GROUP BY 
        t.id, t.title
),
top_movies AS (
    SELECT 
        movie_id, 
        title, 
        cast_count, 
        release_year, 
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        ranked_movies
)
SELECT 
    tm.title,
    tm.release_year,
    tm.cast_count,
    tm.aka_names,
    tm.keywords
FROM 
    top_movies tm
WHERE 
    tm.rank <= 10 
ORDER BY 
    tm.rank;
