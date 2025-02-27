WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rn
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COALESCE(mci.note, 'No note') AS note
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        m.title,
        m.production_year,
        co.company_name,
        co.company_type,
        COALESCE(mkc.keyword_count, 0) AS keyword_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        CompanyDetails co ON m.title = co.movie_id
    LEFT JOIN 
        MovieKeywordCounts mkc ON m.title = mkc.movie_id
    WHERE 
        m.rn = 1
)
SELECT 
    cm.title,
    cm.production_year,
    cm.company_name,
    cm.company_type,
    cm.keyword_count,
    CASE 
        WHEN cm.keyword_count > 5 THEN 'Popular'
        WHEN cm.keyword_count IS NULL THEN 'No keywords'
        ELSE 'Less popular'
    END AS popularity
FROM 
    CompleteMovieInfo cm
WHERE 
    cm.production_year > 2000
ORDER BY 
    cm.production_year DESC, cm.keyword_count DESC
LIMIT 10;
