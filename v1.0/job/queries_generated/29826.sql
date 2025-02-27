WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title ak
    JOIN 
        title m ON ak.movie_id = m.id
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
), FilteredMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year,
        total_cast, 
        aka_names, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        total_cast > 5 AND 
        production_year BETWEEN 2000 AND 2023
),
FinalOutput AS (
    SELECT 
        f.movie_title, 
        f.production_year,
        f.total_cast, 
        f.aka_names,
        f.keywords,
        ROW_NUMBER() OVER (ORDER BY f.production_year DESC, f.total_cast DESC) AS rank
    FROM 
        FilteredMovies f
)
SELECT 
    movie_title,
    production_year,
    total_cast,
    aka_names,
    keywords,
    rank
FROM 
    FinalOutput
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    total_cast DESC;
