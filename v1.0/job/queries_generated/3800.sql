WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        SUM(CASE WHEN co.kind = 'Director' THEN 1 ELSE 0 END) AS directed_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_type co ON mc.company_type_id = co.id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 1
),
TrendingKeywords AS (
    SELECT 
        mw.keyword,
        COUNT(DISTINCT mw.movie_id) AS movie_count
    FROM 
        movie_keyword mw
    GROUP BY 
        mw.keyword
    HAVING 
        COUNT(DISTINCT mw.movie_id) > 5
)
SELECT 
    rt.title,
    rt.production_year,
    am.name AS actor_name,
    am.movie_count,
    tk.keyword AS trending_keyword
FROM 
    RankedTitles rt
JOIN 
    ActorMovies am ON am.movie_count > 3
LEFT JOIN 
    TrendingKeywords tk ON rt.title_id = tk.keyword
WHERE 
    rt.year_rank <= 10 
    AND rt.title IS NOT NULL 
ORDER BY 
    rt.production_year DESC, 
    am.movie_count DESC, 
    tk.movie_count DESC;
