
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title AS a 
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        cast_info AS c ON a.id = c.movie_id
    JOIN 
        aka_name AS ak ON c.person_id = ak.person_id
    WHERE 
        a.production_year >= 2000 
        AND a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    actors,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
