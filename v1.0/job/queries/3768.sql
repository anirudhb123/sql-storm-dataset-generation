WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
RecentMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count = 1
),
MovieKeywordCounts AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
TitleInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(kw.keyword_count, 0) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywordCounts kw ON m.id = kw.movie_id
)
SELECT 
    ti.title,
    ti.keyword_count,
    CASE 
        WHEN ti.keyword_count > 5 THEN 'Popular'
        ELSE 'Less Popular'
    END AS popularity_status,
    RANK() OVER (ORDER BY ti.keyword_count DESC) AS popularity_rank
FROM 
    TitleInfo ti
JOIN 
    RecentMovies rm ON ti.title = rm.title
WHERE 
    ti.keyword_count IS NOT NULL
ORDER BY 
    ti.keyword_count DESC;
