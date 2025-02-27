WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT p.info, '; ') AS person_info,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN 
        person_info p ON ci.person_id = p.person_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
)

SELECT 
    rm.movie_title,
    rm.production_year,
    rm.keyword_count,
    rm.cast_names,
    rm.person_info
FROM 
    RankedMovies rm
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;

This SQL query benchmarks string processing by aggregating and manipulating data from multiple tables related to movies, keywords, casting, and personal information. It creates a CTE (Common Table Expression) that ranks movies by their number of keywords per production year and selects the top 5 movies with the most keywords from each year. The results provide a clear view of the most keyword-rich movies along with their cast and related personal information.
