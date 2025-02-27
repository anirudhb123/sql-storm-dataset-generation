WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopCast AS (
    SELECT 
        c.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY ak.name) AS actor_rank
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
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
TotalMovies AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        CASE 
            WHEN mk.keyword_count IS NOT NULL THEN 'Keyworded'
            ELSE 'Not Keyworded'
        END AS keyword_status
    FROM 
        aka_title m
    LEFT JOIN 
        MovieKeywordCounts mkc ON m.id = mkc.movie_id
    LEFT JOIN 
        (SELECT DISTINCT movie_id FROM movie_keyword) mk ON m.id = mk.movie_id
),
FinalReport AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        c.actor_name,
        wc.keyword_count,
        CASE 
            WHEN m.keyword_status = 'Keyworded' AND wc.keyword_count > 5 THEN 'Popular'
            ELSE 'Standard'
        END AS movie_popularity
    FROM 
        TotalMovies m
    LEFT JOIN 
        TopCast c ON m.movie_id = c.movie_id AND c.actor_rank <= 3
    LEFT JOIN 
        (SELECT movie_id, SUM(keyword_count) AS keyword_count FROM MovieKeywordCounts GROUP BY movie_id) wc ON m.movie_id = wc.movie_id
    WHERE 
        m.keyword_status IS NOT NULL AND (m.keyword_status = 'Keyworded' OR wc.keyword_count > 0)
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    STRING_AGG(DISTINCT fr.actor_name, ', ') AS actors,
    fr.keyword_count,
    fr.movie_popularity
FROM 
    FinalReport fr
GROUP BY 
    fr.movie_id, fr.title, fr.production_year
HAVING 
    COUNT(fr.actor_name) > 1
ORDER BY 
    fr.production_year DESC, fr.movie_popularity, fr.title;
