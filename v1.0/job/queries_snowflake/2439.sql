
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    WHERE 
        mt.production_year IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 5
),
MovieKeyInfo AS (
    SELECT 
        fk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword fk
    JOIN 
        keyword k ON fk.keyword_id = k.id
    GROUP BY 
        fk.movie_id
),
MoviesWithInfo AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mki.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeyInfo mki ON fm.movie_id = mki.movie_id
)
SELECT 
    mw.movie_id,
    mw.title,
    mw.production_year,
    mw.keywords,
    CASE 
        WHEN mw.production_year < 2000 THEN 'Classic'
        WHEN mw.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    CASE 
        WHEN mw.production_year IS NULL THEN 'Unknown Production Year'
        ELSE CAST(mw.production_year AS STRING)
    END AS production_year_description
FROM 
    MoviesWithInfo mw
ORDER BY 
    mw.production_year DESC, 
    mw.title;
