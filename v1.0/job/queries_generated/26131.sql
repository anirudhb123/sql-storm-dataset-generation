WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
TopKeywords AS (
    SELECT 
        keyword,
        COUNT(*) AS keyword_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
    GROUP BY 
        keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 10
)
SELECT 
    a.name AS actor_name,
    m.movie_title,
    t.production_year,
    k.keyword,
    COUNT(ci.id) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    RankedMovies r ON m.title = r.movie_title AND m.production_year = r.production_year
WHERE 
    k.keyword IN (SELECT keyword FROM TopKeywords)
GROUP BY 
    a.name, m.movie_title, t.production_year, k.keyword
ORDER BY 
    COUNT(ci.id) DESC, a.name;

This SQL query benchmarks string processing by extracting key data from several tables related to movies, actors, and keywords. It starts by creating a `RankedMovies` common table expression (CTE) that ranks movies by their production year and collects associated keywords. A second CTE, `TopKeywords`, identifies the top 10 keywords from those movies. Finally, the main query pulls together actor names, movie titles, production years, and the relevant keywords, aggregating data to show the actor's collaborations filtered by the top keywords. The results are ordered by the count of cast appearances, offering a detailed benchmarking scenario for string-processing capabilities across multiple joins and aggregations.
