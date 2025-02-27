WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_members
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name an ON ci.person_id = an.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id
), 
PopularMovies AS (
    SELECT 
        title, 
        production_year,
        total_cast,
        cast_members,
        DENSE_RANK() OVER (ORDER BY total_cast DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    pm.title, 
    pm.production_year, 
    pm.total_cast, 
    pm.cast_members,
    (SELECT COUNT(*) FROM title WHERE kind_id = 1 AND production_year = pm.production_year) AS total_titles_of_same_year
FROM 
    PopularMovies pm
WHERE 
    pm.total_cast > (SELECT AVG(total_cast) FROM RankedMovies)
ORDER BY 
    pm.rank
LIMIT 10;
