WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN
        cast_info c ON a.movie_id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
MovieCompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(mcc.company_count, 0) AS company_count,
        COALESCE(kc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN COALESCE(mcc.company_count, 0) > 5 AND COALESCE(kc.keyword_count, 0) > 10 THEN 'Highly Rated'
            WHEN COALESCE(mcc.company_count, 0) > 2 AND COALESCE(kc.keyword_count, 0) > 5 THEN 'Moderately Rated'
            ELSE 'Low Rated'
        END AS rating_category
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieCompanyCounts mcc ON m.movie_id = mcc.movie_id
    LEFT JOIN 
        KeywordCounts kc ON m.movie_id = kc.movie_id
    WHERE 
        m.rank <= 10
)
SELECT 
    m.title,
    m.production_year,
    m.company_count,
    m.keyword_count,
    m.rating_category,
    CASE 
        WHEN m.company_count IS NULL THEN 'No Companies'
        ELSE 'Companies Present'
    END AS company_status,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = m.movie_id AND 
        mi.info LIKE '%Award%'
    ) AS award_info_count
FROM 
    MoviesWithInfo m
ORDER BY 
    m.production_year DESC,
    m.company_count DESC;
