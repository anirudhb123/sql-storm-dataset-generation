WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank 
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
TopActors AS (
    SELECT 
        a.name,
        a.person_id,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 5
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS actor,
    COALESCE(kc.keyword_count, 0) AS keyword_count,
    COUNT(DISTINCT m.id) AS related_companies,
    CASE 
        WHEN YEAR(tm.production_year) > 2000 THEN 'Modern'
        WHEN YEAR(tm.production_year) BETWEEN 1980 AND 2000 THEN 'Classic'
        ELSE 'Vintage'
    END AS era_category
FROM 
    RankedMovies tm
LEFT JOIN 
    TopActors ta ON tm.title_id = (SELECT mc.movie_id FROM cast_info mc WHERE mc.person_id = ta.person_id LIMIT 1)
LEFT JOIN 
    KeywordCounts kc ON tm.title_id = kc.movie_id
LEFT JOIN 
    movie_companies m ON tm.title_id = m.movie_id
WHERE 
    (tm.production_year IS NOT NULL AND tm.production_year >= 1980)
    AND (kc.keyword_count IS NULL OR kc.keyword_count < 5)
GROUP BY 
    tm.title, 
    tm.production_year, 
    ta.name, 
    kc.keyword_count
ORDER BY 
    tm.production_year DESC, 
    keyword_count DESC NULLS LAST
OPTION (MAXRECURSION 1000);
