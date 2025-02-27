WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year
), MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.rank_by_cast <= 5 THEN 'Top Cast'
            ELSE 'Regular Cast'
        END AS cast_category
    FROM 
        RankedMovies rm
), KeywordMovies AS (
    SELECT 
        m.title,
        k.keyword
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
), FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        md.cast_category,
        STRING_AGG(DISTINCT km.keyword, ', ') AS keywords
    FROM 
        MovieDetails md
    LEFT JOIN 
        KeywordMovies km ON md.title = km.title
    GROUP BY 
        md.title, md.production_year, md.cast_category
)
SELECT 
    f.title,
    f.production_year,
    f.cast_category,
    COALESCE(f.keywords, 'No Keywords') AS keywords
FROM 
    FinalOutput f
WHERE 
    f.production_year > 2000
ORDER BY 
    f.production_year DESC, 
    f.cast_category ASC, 
    f.title;
