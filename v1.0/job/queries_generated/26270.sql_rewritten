WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        title t
    JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
filtered_movies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        total_cast, 
        aka_names, 
        keywords
    FROM 
        ranked_movies
    WHERE 
        rank_by_cast <= 10  
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.aka_names,
    fm.keywords
FROM 
    filtered_movies fm
ORDER BY 
    fm.production_year DESC, fm.total_cast DESC;