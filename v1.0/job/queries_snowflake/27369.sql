
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names, 
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        num_cast_members,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
),
MovieKeywords AS (
    SELECT 
        t.title,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
)
SELECT 
    tm.title AS "Movie Title",
    tm.production_year AS "Year",
    tm.num_cast_members AS "Number of Cast Members",
    tm.cast_names AS "Cast Names",
    LISTAGG(mk.keyword, ', ') WITHIN GROUP (ORDER BY mk.keyword) AS "Keywords"
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.title = mk.title
GROUP BY 
    tm.title, tm.production_year, tm.num_cast_members, tm.cast_names
ORDER BY 
    tm.num_cast_members DESC;
