WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT ak.name) AS alternate_names
    FROM 
        aka_title ak 
    JOIN 
        title t ON ak.movie_id = t.id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredTitles AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.alternate_names
    FROM 
        RankedMovies rm
    WHERE 
        rm.production_year > 2000 AND 
        rm.total_cast > 5
    ORDER BY 
        rm.total_cast DESC
    LIMIT 10
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
    ft.movie_id,
    ft.title,
    ft.production_year,
    ft.total_cast,
    ft.alternate_names,
    mk.keywords
FROM 
    FilteredTitles ft
LEFT JOIN 
    MovieKeywords mk ON ft.movie_id = mk.movie_id
ORDER BY 
    ft.production_year DESC, ft.total_cast DESC;
