
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title a
    JOIN 
        movie_companies mc ON a.id = mc.movie_id
    JOIN 
        cast_info c ON a.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000 
    GROUP BY 
        a.id, a.title, a.production_year
),
TopMovies AS (
    SELECT
        movie_title,
        production_year,
        cast_count,
        aka_names,
        keywords,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    aka_names,
    keywords
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC;
