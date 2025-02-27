WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rn
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.title, a.production_year
),
MoviesWithKeywords AS (
    SELECT 
        m.title,
        m.production_year,
        k.keyword,
        COALESCE(s.subject_count, 0) AS subject_count
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_keyword mk ON m.title = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN (
        SELECT 
            movie_id, COUNT(DISTINCT subject_id) AS subject_count
        FROM 
            complete_cast
        GROUP BY 
            movie_id
    ) s ON m.title = s.movie_id
    WHERE 
        m.rn <= 5 
)
SELECT 
    mw.title,
    mw.production_year,
    mw.keyword,
    CASE 
        WHEN mw.subject_count > 10 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity,
    COALESCE(NULLIF(mw.keyword, ''), 'No Keyword') AS processed_keyword
FROM 
    MoviesWithKeywords mw
WHERE 
    mw.keyword IS NOT NULL
ORDER BY 
    mw.production_year DESC, 
    mw.subject_count DESC;
