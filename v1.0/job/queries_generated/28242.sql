WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_companies mc ON mc.movie_id = m.id
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        complete_cast cc ON cc.movie_id = m.id
    JOIN 
        cast_info ci ON ci.movie_id = m.id
    JOIN 
        aka_name an ON an.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.id
    LEFT JOIN 
        keyword kw ON kw.id = mk.keyword_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
),

TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        cast_count,
        cast_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)

SELECT
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10;
