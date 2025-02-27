WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS alternative_titles,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id,
        cast_count,
        alternative_titles,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    k.kind,
    tm.cast_count,
    tm.alternative_titles,
    tm.keywords
FROM 
    TopMovies tm
JOIN 
    kind_type k ON tm.kind_id = k.id
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.cast_count DESC;
