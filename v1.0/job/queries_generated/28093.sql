WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        GROUP_CONCAT(DISTINCT a.name) AS actors,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.id) AS cast_count
    FROM 
        title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        aka_title at ON t.id = at.movie_id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
    GROUP BY 
        t.id, t.title, t.production_year
),
average_cast AS (
    SELECT 
        AVG(cast_count) AS avg_cast_size
    FROM 
        movie_data
),
movies_above_avg AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.cast_count
    FROM 
        movie_data md
    JOIN 
        average_cast ac ON md.cast_count > ac.avg_cast_size
)
SELECT 
    movie_title,
    production_year,
    actors,
    keywords,
    cast_count
FROM 
    movies_above_avg
ORDER BY 
    production_year DESC, 
    cast_count DESC;

This SQL query first aggregates data about movies released from the year 2000 onwards, collecting titles, production years, actor names, and associated keywords, while also counting the number of distinct casts per movie. It then calculates the average number of cast members for these movies and selects those movies that exceed this average, finally ordering the results by production year and cast size for insightful analysis.
