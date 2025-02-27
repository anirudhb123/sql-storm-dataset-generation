WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year AS year,
        GROUP_CONCAT(DISTINCT ak.name) AS alternate_names,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        c.role_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, c.role_id
),
TopMovies AS (
    SELECT 
        movie_title,
        year,
        alternate_names,
        keywords,
        cast_count,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY cast_count DESC) AS rank
    FROM 
        MovieDetails
)
SELECT 
    year,
    movie_title,
    alternate_names,
    keywords,
    cast_count
FROM 
    TopMovies
WHERE 
    rank <= 5
ORDER BY 
    year, rank;

This query retrieves the top 5 movies for each production year since 2000, along with their alternate names, keywords, and the number of cast members. It utilizes CTEs (Common Table Expressions) to organize and filter the data efficiently, showcasing various string processing techniques like concatenation and aggregation.
