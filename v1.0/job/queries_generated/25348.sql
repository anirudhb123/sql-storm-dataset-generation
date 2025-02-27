WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info AS c ON c.movie_id = t.id
    LEFT JOIN 
        aka_name AS ak ON ak.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        aka_names,
        keywords,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    string_agg(DISTINCT ak.name, ', ') AS all_aka_names,
    string_agg(DISTINCT k.keyword, ', ') AS all_keywords
FROM 
    TopMovies AS tm
LEFT JOIN 
    aka_title AS t ON t.id = tm.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ANY(tm.aka_names)
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = tm.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.cast_count
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;
