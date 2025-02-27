WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
    WHERE 
        production_year > 2000
),
MovieDetails AS (
    SELECT 
        tm.title, 
        tm.production_year, 
        GROUP_CONCAT(DISTINCT ak.name, ', ') AS aka_names, 
        GROUP_CONCAT(DISTINCT cn.name, ', ') AS companies, 
        GROUP_CONCAT(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        TopMovies tm
    LEFT JOIN 
        aka_title ak ON ak.movie_id = tm.movie_id
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        tm.rank <= 10
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title, 
    md.production_year, 
    md.aka_names, 
    md.companies, 
    md.keywords
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.title ASC;
