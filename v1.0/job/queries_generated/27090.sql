WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        cast_info c ON c.movie_id = mc.movie_id
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
), FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        num_cast_members,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        production_year BETWEEN 2000 AND 2023
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        FilteredMovies m ON m.movie_id = mk.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.num_cast_members,
    f.cast_names,
    mk.keywords
FROM 
    FilteredMovies f
LEFT JOIN 
    MovieKeywords mk ON f.movie_id = mk.movie_id
ORDER BY 
    f.num_cast_members DESC, 
    f.production_year DESC;
