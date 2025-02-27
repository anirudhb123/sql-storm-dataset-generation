WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_members
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        cast_count,
        cast_members,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    m.cast_members,
    mt.kind AS company_type,
    mk.keyword AS keyword_used
FROM 
    TopMovies m
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
LEFT JOIN 
    company_type mt ON mc.company_type_id = mt.id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
WHERE 
    m.rank <= 10
ORDER BY 
    m.cast_count DESC, m.production_year DESC;
