
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT a.name) AS cast_names
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    LISTAGG(m.cast_names, ', ') AS all_cast_names,
    k.keyword AS movie_keyword,
    t.kind AS movie_kind
FROM 
    TopMovies m
JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    aka_title at ON m.movie_id = at.id
JOIN 
    kind_type t ON at.kind_id = t.id
WHERE 
    m.rank <= 10
GROUP BY 
    m.movie_id, m.title, m.production_year, m.cast_count, k.keyword, t.kind
ORDER BY 
    m.cast_count DESC;
