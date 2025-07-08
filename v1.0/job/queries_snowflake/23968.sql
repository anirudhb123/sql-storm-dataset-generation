
WITH RecursiveMovieRanks AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS row_num,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
HighRatedMovies AS (
    SELECT 
        m.movie_id,
        (COUNT(DISTINCT ci.person_id) / NULLIF(mk.keyword_count, 0)) AS average_role_per_keyword
    FROM 
        complete_cast m
    LEFT JOIN 
        MovieKeywordCounts mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    WHERE 
        m.status_id IS NOT NULL
    GROUP BY 
        m.movie_id, mk.keyword_count
    HAVING 
        COUNT(DISTINCT ci.person_id) > 10 AND 
        (COUNT(DISTINCT ci.person_id) / NULLIF(mk.keyword_count, 0) > 1)
),
AggregateRanking AS (
    SELECT 
        r.movie_id,
        r.title,
        COALESCE(AVG(h.average_role_per_keyword), 0) AS avg_rank,
        ROW_NUMBER() OVER (ORDER BY COALESCE(AVG(h.average_role_per_keyword), 0) DESC) AS rank
    FROM 
        RecursiveMovieRanks r
    LEFT JOIN 
        HighRatedMovies h ON r.movie_id = h.movie_id
    GROUP BY 
        r.movie_id, r.title
)

SELECT 
    a.title,
    ROUND(a.avg_rank, 2) AS avg_rank,
    CASE
        WHEN a.rank <= 5 THEN 'Top Movie'
        WHEN a.rank <= 10 THEN 'High Rating'
        ELSE 'Average Movie'
    END AS rank_category
FROM 
    AggregateRanking a
WHERE 
    a.avg_rank IS NOT NULL
ORDER BY 
    a.rank ASC;
