WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
DirectorInfo AS (
    SELECT 
        ci.movie_id,
        STRING_AGG(DISTINCT p.info, ', ') AS directors 
    FROM 
        movie_companies ci
    JOIN 
        person_info p ON ci.company_id = p.person_id
    WHERE 
        ci.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Director')
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        tm.cast_count,
        COALESCE(di.directors, 'Unknown') AS directors
    FROM 
        TopMovies tm
    LEFT JOIN 
        DirectorInfo di ON tm.movie_id = di.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.directors,
    COALESCE(SUBSTRING(mk.keyword FROM 1 FOR 10), 'No Keywords') AS prominent_keyword
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON md.movie_id = mk.movie_id
ORDER BY 
    md.production_year DESC, 
    md.cast_count DESC
LIMIT 10;
