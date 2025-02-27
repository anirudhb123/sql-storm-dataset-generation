WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
    ORDER BY 
        cast_count DESC
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        aliases,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5  -- Filter for movies with more than 5 cast members
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.aliases,
    tm.keywords,
    p.info AS director_info
FROM 
    TopMovies AS tm
LEFT JOIN 
    complete_cast AS cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    person_info AS p ON cc.subject_id = p.person_id 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Director')
WHERE 
    rank <= 10  -- Get top 10 movies
ORDER BY 
    tm.rank;
