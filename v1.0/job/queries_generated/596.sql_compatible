
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.cast_count,
    mk.keyword,
    CASE 
        WHEN mk.keyword IS NULL THEN 'No Keywords'
        ELSE mk.keyword
    END AS keyword_info,
    COALESCE(cm.company_count, 0) AS company_count
FROM 
    RankedMovies m
LEFT JOIN 
    MoviesWithKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovieCount cm ON m.movie_id = cm.movie_id
WHERE 
    m.rank <= 5
ORDER BY 
    m.production_year DESC, m.cast_count DESC;
