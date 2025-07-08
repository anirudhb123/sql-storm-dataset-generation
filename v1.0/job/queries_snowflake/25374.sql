WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000 
),
HighestRatedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        COUNT(ci.person_id) AS cast_count
    FROM 
        MovieDetails md
    JOIN 
        complete_cast cc ON md.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        md.movie_id, md.title, md.production_year
    HAVING 
        COUNT(ci.person_id) > 5 
),
KeywordStats AS (
    SELECT 
        md.title,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        MovieDetails md
    JOIN 
        keyword k ON md.keyword = k.keyword
    GROUP BY 
        md.title
)
SELECT 
    hr.title,
    hr.production_year,
    hr.cast_count,
    ks.keyword_count
FROM 
    HighestRatedMovies hr
JOIN 
    KeywordStats ks ON hr.title = ks.title
ORDER BY 
    hr.production_year DESC, 
    hr.cast_count DESC;