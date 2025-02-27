WITH RankedTitles AS (
    SELECT 
        t.id AS title_id, 
        t.title AS title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        title t
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
ActorDetails AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        ac.movie_count,
        ROW_NUMBER() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts ac ON a.person_id = ac.person_id
),
KeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        t.title AS movie_title,
        wc.keyword_count,
        t.production_year
    FROM 
        title t
    JOIN 
        KeywordCounts wc ON t.id = wc.movie_id
)
SELECT 
    ad.actor_name, 
    ad.movie_count AS total_movies, 
    rt.title AS latest_title,
    rt.production_year, 
    mw.keyword_count AS available_keywords
FROM 
    ActorDetails ad
JOIN 
    RankedTitles rt ON ad.actor_rank = rt.title_rank
LEFT JOIN 
    MoviesWithKeywords mw ON rt.title = mw.movie_title
WHERE 
    ad.actor_rank <= 10
ORDER BY 
    ad.movie_count DESC, rt.production_year DESC;
