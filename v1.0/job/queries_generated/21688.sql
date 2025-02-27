WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank,
        t.kind_id,
        COALESCE(mb.info, 'No info') AS movie_bio
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = t.id
    LEFT JOIN 
        movie_info mb ON mb.movie_id = t.id AND mb.info_type_id = (SELECT id FROM info_type WHERE info = 'bio')
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, mb.info
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.rank,
        kt.kind AS movie_kind,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON kt.id = rm.kind_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.movie_id
    WHERE 
        rm.rank <= 5 AND 
        (rm.total_cast IS NULL OR rm.total_cast > 0) AND 
        (rm.title LIKE '%Love%' OR rm.production_year > 2020) 
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.total_cast, rm.rank, kt.kind
),

MovieGenres AS (
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
    fm.title,
    fm.production_year,
    fm.total_cast,
    fm.movie_kind,
    fm.company_count,
    COALESCE(mg.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN fm.total_cast > 50 THEN 'Large Cast'
        WHEN fm.total_cast < 5 THEN 'Small Cast'
        ELSE 'Medium Cast'
    END AS cast_category
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieGenres mg ON fm.movie_id = mg.movie_id
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast DESC 
LIMIT 10;
