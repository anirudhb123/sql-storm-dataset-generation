
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info c ON at.movie_id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),
MovieKeywords AS (
    SELECT 
        fk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword fk
    JOIN 
        keyword k ON fk.keyword_id = k.id
    GROUP BY 
        fk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.movie_id = mk.movie_id
)
SELECT 
    mwk.movie_id,
    mwk.title,
    mwk.production_year,
    mwk.keywords,
    CASE 
        WHEN mwk.production_year IS NULL THEN 'Year not available' 
        ELSE CONCAT('Released in ', mwk.production_year) 
    END AS release_info,
    (SELECT 
         CASE 
             WHEN AVG(cast_count) IS NULL THEN 'No cast info'
             ELSE CAST(AVG(cast_count) AS TEXT) 
         END 
     FROM 
         (SELECT COUNT(DISTINCT person_id) AS cast_count 
          FROM cast_info 
          WHERE movie_id IN (SELECT movie_id FROM FilteredMovies) 
          GROUP BY movie_id) AS avg_cast) AS average_cast_size
FROM 
    MoviesWithKeywords mwk
ORDER BY 
    mwk.production_year DESC NULLS LAST;
