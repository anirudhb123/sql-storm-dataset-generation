WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id
),

TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        cast_count,
        aka_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT 
    m.movie_title,
    m.production_year,
    m.cast_count,
    m.aka_names,
    k.keyword AS featured_keyword,
    ct.kind AS company_type
FROM 
    TopMovies m
JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    m.rank <= 10 
    AND k.keyword ILIKE '%drama%' 
ORDER BY 
    m.cast_count DESC, 
    m.production_year DESC;

This query is designed to benchmark string processing capabilities by analyzing movie data based on their popularity, cast size, and associated keywords. It ranks the movies by their cast count, fetches additional data such as alternative names and keywords, and filters results to only include the top 10 most popular drama films. The usage of string aggregation and filtering with `ILIKE` enhances the complexity and effectiveness of string processing within the dataset.
