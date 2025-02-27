WITH ranked_titles AS (
    SELECT 
        a.id AS title_id,
        a.title,
        a.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.id) DESC) AS rank_within_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON c.movie_id = a.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        a.id, a.title, a.production_year
),
filtered_movies AS (
    SELECT 
        r.title_id,
        r.title,
        r.production_year,
        r.cast_count,
        r.aka_names
    FROM 
        ranked_titles r
    WHERE 
        r.rank_within_year <= 5  -- Top 5 movies per year
),
detailed_movie_info AS (
    SELECT 
        f.title_id,
        f.title,
        f.production_year,
        f.cast_count,
        f.aka_names,
        m.info AS movie_notes,
        k.keyword
    FROM 
        filtered_movies f
    LEFT JOIN 
        movie_info m ON m.movie_id = f.title_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = f.title_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    d.title,
    d.production_year,
    d.cast_count,
    d.aka_names,
    STRING_AGG(DISTINCT d.movie_notes, '; ') AS combined_notes,
    STRING_AGG(DISTINCT d.keyword, ', ') AS keywords
FROM 
    detailed_movie_info d
GROUP BY 
    d.title_id, d.title, d.production_year, d.cast_count, d.aka_names
ORDER BY 
    d.production_year DESC,
    d.cast_count DESC;
