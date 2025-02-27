WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        complete_cast c ON t.id = c.movie_id
    JOIN 
        cast_info ca ON c.subject_id = ca.id
    GROUP BY 
        a.id, t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.total_cast,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN rm.total_cast > 10 THEN 'Large Cast'
        WHEN rm.total_cast BETWEEN 5 AND 10 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size
FROM 
    RecentMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
