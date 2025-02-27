WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovieDetails AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY total_cast_members DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    rmd.movie_id,
    rmd.title,
    rmd.production_year,
    rmd.total_cast_members,
    rmd.cast_names,
    rmd.keywords,
    rk.company_type
FROM 
    RankedMovieDetails rmd
LEFT JOIN 
    movie_companies mc ON rmd.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    rk.rank <= 10
ORDER BY 
    rmd.total_cast_members DESC;

This SQL query processes string information from multiple tables to analyze movies produced after 2000, counting their cast members and aggregating their names and associated keywords. It ultimately ranks the top 10 movies based on cast size while also joining company types related to those movies.
