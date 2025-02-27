WITH RankedMovies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank_within_year
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_within_year <= 5
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
RecentActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        amc.movie_count
    FROM 
        aka_name ak
    JOIN 
        ActorMovieCounts amc ON ak.person_id = amc.person_id
    WHERE 
        amc.movie_count > 3
)
SELECT 
    t.title,
    t.production_year,
    ra.name AS actor_name,
    amc.movie_count,
    COALESCE(NULLIF(SUBSTRING(t.title, 1, 5), ''), 'Untitled') AS short_title,
    CASE 
        WHEN t.production_year < 2000 THEN 'Classic'
        WHEN t.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category
FROM 
    TopTitles t
LEFT JOIN 
    cast_info ci ON t.title_id = ci.movie_id
LEFT JOIN 
    RecentActors ra ON ci.person_id = ra.person_id
WHERE 
    t.production_year IS NOT NULL
ORDER BY 
    t.production_year DESC, t.title;
