WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.title_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.title_id
    WHERE 
        rm.rank <= 10
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
CastStatistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN ci.role_id IS NOT NULL THEN ci.person_id END) AS credited_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        fm.title_id,
        fm.title,
        fm.production_year,
        fm.keywords,
        fm.company_count,
        COALESCE(cs.total_cast, 0) AS total_cast,
        COALESCE(cs.credited_cast, 0) AS credited_cast
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CastStatistics cs ON cs.movie_id = fm.title_id
)
SELECT 
    md.title,
    md.production_year,
    md.keywords,
    md.company_count,
    md.total_cast,
    md.credited_cast,
    CASE 
        WHEN md.total_cast = 0 THEN 'No Cast'
        WHEN md.credited_cast = 0 THEN 'All Uncredited'
        ELSE 'Mixed'
    END AS cast_status
FROM 
    MovieDetails md
WHERE 
    md.company_count > 1
ORDER BY 
    md.production_year DESC, md.title;
