WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cr.total_cast, 0) AS total_cast,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN rm.rank_title = 1 THEN 'First Title of Year'
            WHEN rm.rank_title = total_titles THEN 'Last Title of Year'
            ELSE 'Intermediate Title'
        END AS title_rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_cast,
        md.keywords,
        md.title_rank
    FROM 
        MovieDetails md
    WHERE 
        md.total_cast > 0 
        AND md.production_year BETWEEN 2000 AND 2020
        AND md.title_rank IN ('First Title of Year', 'Last Title of Year')
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_cast,
    f.keywords,
    f.title_rank,
    CASE 
        WHEN f.keywords IS NULL THEN 'No Keywords Available'
        ELSE 'Keywords Present'
    END AS keyword_status,
    COALESCE(NULLIF(f.title, ''), 'Untitled') AS final_title,
    CONCAT(f.title, ' (', f.production_year, ')') AS formatted_title
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.title;
