WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    GROUP BY 
        a.title, a.production_year
),
MovieDetails AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.cast_count, 
        GROUP_CONCAT(DISTINCT an.name) AS actors,
        (SELECT COUNT(DISTINCT mk.keyword_id) 
         FROM movie_keyword mk 
         WHERE mk.movie_id = (SELECT id FROM aka_title WHERE title = rm.title LIMIT 1)) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON rm.title = (SELECT title FROM aka_title WHERE id = c.movie_id LIMIT 1)
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.title, rm.production_year, rm.cast_count
)
SELECT 
    md.title, 
    md.production_year, 
    md.cast_count, 
    md.actors, 
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'Highly Tagged'
        WHEN md.cast_count > 20 THEN 'Star-studded'
        ELSE 'Standard'
    END AS movie_category
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC;

