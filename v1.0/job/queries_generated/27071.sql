WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        p.name AS person_name,
        c.nr_order AS cast_order,
        k.keyword AS movie_keyword,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order) AS rank
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info m ON a.id = m.movie_id
    WHERE 
        a.production_year >= 2000
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        movie_title,
        person_name,
        production_year,
        movie_keyword
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    movie_title,
    ARRAY_AGG(DISTINCT person_name) AS cast_names,
    ARRAY_AGG(DISTINCT movie_keyword) AS keywords,
    MIN(production_year) AS earliest_year
FROM 
    TopMovies
GROUP BY 
    movie_title
ORDER BY 
    earliest_year DESC;
