WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS alternate_titles,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_title ak ON t.id = ak.movie_id
    GROUP BY 
        t.id
),
TopRatedMovies AS (
    SELECT 
        rm.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    TRIM(m.movie_id) AS movie_id,
    UPPER(m.title) AS title_upper,
    m.production_year,
    m.cast_count,
    m.alternate_titles,
    m.keywords
FROM 
    TopRatedMovies m
WHERE 
    m.rank <= 5
ORDER BY 
    m.production_year DESC, 
    m.cast_count DESC;

This SQL query benchmarks string processing by aggregating data from various tables related to movies, including alternate titles and keywords. It ranks the movies by the number of distinct cast members per production year, retrieving the top 5 for each year, and formats the title to uppercase for consistent string processing visualization.
