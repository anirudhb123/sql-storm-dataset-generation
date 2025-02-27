WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY k.keyword) AS keyword_rank
    FROM 
        TopMovies m
    JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    k.keyword AS movie_keyword,
    COALESCE(m.info, 'No additional info') AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Tagline')
JOIN 
    MovieKeywords k ON t.production_year = k.production_year AND k.keyword_rank <= 3
WHERE 
    a.name IS NOT NULL
ORDER BY 
    t.production_year DESC, a.name;
