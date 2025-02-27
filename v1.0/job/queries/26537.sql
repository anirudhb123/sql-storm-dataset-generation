WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = c.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        aka_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 10
)

SELECT 
    tm.title, 
    tm.production_year, 
    tm.cast_count, 
    tm.aka_names,
    tm.keywords,
    CASE 
        WHEN tm.production_year < 2010 THEN 'Legacy'
        WHEN tm.production_year BETWEEN 2010 AND 2015 THEN 'Recent Classic'
        ELSE 'Modern'
    END AS era_category
FROM 
    TopMovies tm
ORDER BY 
    tm.cast_count DESC;
