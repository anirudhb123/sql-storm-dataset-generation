WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        nt.kind AS genre,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS known_aliases
    FROM 
        aka_title AT
    JOIN 
        title t ON AT.id = t.id
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    JOIN 
        kind_type nt ON nt.id = t.kind_id
    GROUP BY 
        t.id, t.title, t.production_year, nt.kind
),
TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    m.title AS "Movie Title",
    m.production_year AS "Year of Production",
    m.genre AS "Genre",
    m.cast_count AS "Number of Unique Cast Members",
    m.known_aliases AS "Known Aliases"
FROM 
    TopMovies m
WHERE 
    m.rank <= 10
ORDER BY 
    m.cast_count DESC;
