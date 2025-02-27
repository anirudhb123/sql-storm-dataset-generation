WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON mk.movie_id = a.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
FilteredMovies AS (
    SELECT 
        title,
        production_year,
        keyword
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MovieDetails AS (
    SELECT 
        f.title,
        f.production_year,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT i.info, ', ') AS additional_info
    FROM 
        FilteredMovies f
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = (SELECT id FROM aka_title WHERE title = f.title AND production_year = f.production_year)
    LEFT JOIN 
        cast_info c ON c.movie_id = cc.movie_id
    LEFT JOIN 
        movie_info i ON i.movie_id = cc.movie_id
    GROUP BY 
        f.title, f.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.additional_info,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    MovieDetails md
JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = md.title AND production_year = md.production_year)
JOIN 
    keyword k ON k.id = mk.keyword_id
GROUP BY 
    md.title, md.production_year, md.cast_count, md.additional_info
ORDER BY 
    md.production_year DESC, md.cast_count DESC;
