WITH movie_year_stats AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title a
    JOIN 
        complete_cast cc ON cc.movie_id = a.id
    JOIN 
        cast_info c ON c.movie_id = a.id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
keyword_stats AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        title m ON m.id = mk.movie_id
    GROUP BY 
        m.id
)
SELECT 
    my.movie_title,
    my.production_year,
    my.cast_count,
    my.aka_names,
    ks.keywords
FROM 
    movie_year_stats my
LEFT JOIN 
    keyword_stats ks ON ks.movie_id = my.movie_id
WHERE 
    my.production_year BETWEEN 2000 AND 2023
ORDER BY 
    my.production_year DESC,
    my.cast_count DESC;
