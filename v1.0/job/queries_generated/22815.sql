WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithCast AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(STRING_AGG(DISTINCT a.name, ', '), '(No Cast)') AS cast_names,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info c ON c.movie_id = rm.title_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        rm.title_id, rm.title, rm.production_year
),
MovieKeywords AS (
    SELECT 
        m.title_id,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        MoviesWithCast m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.title_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.title_id
),
FinalReport AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.cast_names,
        mw.cast_count,
        COALESCE(mk.keyword_count, 0) AS total_keywords,
        mk.keywords
    FROM 
        MoviesWithCast mw
    LEFT JOIN 
        MovieKeywords mk ON mk.title_id = mw.title_id
    WHERE 
        mw.cast_count > 5 OR mw.production_year IS NULL
)
SELECT 
    FR.*,
    CASE 
        WHEN FR.total_keywords IS NULL OR FR.total_keywords = 0 THEN 'No Keywords'
        ELSE 'Has Keywords'
    END AS keyword_status
FROM 
    FinalReport FR
ORDER BY 
    FR.production_year DESC NULLS LAST, 
    FR.title;
