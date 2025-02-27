WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast_size <= 5
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        MovieKeywords mk ON fm.movie_id = mk.movie_id
),
UniqueGenres AS (
    SELECT DISTINCT 
        kt.kind AS genre
    FROM 
        kind_type kt
    JOIN 
        aka_title at ON kt.id = at.kind_id
),
OutstandingMovies AS (
    SELECT 
        md.*, 
        CASE 
            WHEN md.production_year < 2000 
            THEN 'Classic'
            WHEN md.production_year BETWEEN 2000 AND 2010 
            THEN 'Modern'
            ELSE 'New Age'
        END AS era,
        ROW_NUMBER() OVER (ORDER BY md.production_year DESC) as movie_rank
    FROM 
        MovieDetails md
)
SELECT 
    om.title,
    om.production_year,
    om.keywords,
    om.era,
    ug.genre
FROM 
    OutstandingMovies om
LEFT JOIN 
    UniqueGenres ug ON 1=1
WHERE 
    (om.production_year IS NULL OR om.production_year > 1990)
    AND (om.keywords IS NOT NULL OR om.keywords <> 'No Keywords')
ORDER BY 
    om.production_year DESC, 
    om.title
LIMIT 10
OFFSET 5;
