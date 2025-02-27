WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast,
        actor_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.actor_names,
    tm.keywords,
    ct.kind AS company_type
FROM 
    TopMovies tm
JOIN 
    movie_companies mc ON tm.movie_id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.total_cast DESC;

This query benchmarks string processing by aggregating actors' names and keywords for the top 10 movies based on the total number of cast members. It effectively showcases SQL's ability to process and manipulate string data using functions such as `STRING_AGG` for concatenation, while also utilizing window functions for ranking.
