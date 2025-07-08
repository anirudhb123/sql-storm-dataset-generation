WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
), 
MovieCastCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS cast_member_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
), 
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), 
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(mcc.cast_member_count, 0) AS total_cast_members,
    COALESCE(cmc.company_count, 0) AS total_companies,
    COALESCE(mkc.keyword_count, 0) AS total_keywords,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top 5 of Year'
        ELSE 'Below Top 5'
    END AS rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCastCounts mcc ON rm.movie_id = mcc.movie_id
LEFT JOIN 
    CompanyMovieCounts cmc ON rm.movie_id = cmc.movie_id
LEFT JOIN 
    MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.title;
