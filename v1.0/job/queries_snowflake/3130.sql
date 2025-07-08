WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank,
        COUNT(DISTINCT ci.person_id) AS num_cast
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
RecentMovies AS (
    SELECT 
        title_id,
        title,
        production_year,
        num_cast
    FROM 
        RankedMovies
    WHERE 
        production_year >= (SELECT MAX(production_year) FROM title) - 5
),
TrendingActors AS (
    SELECT 
        a.name,
        COUNT(DISTINCT ci.movie_id) AS num_movies
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 2
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(ta.name, 'Unknown Actor') AS trending_actor,
    rm.num_cast
FROM 
    RecentMovies rm
LEFT JOIN 
    TrendingActors ta ON rm.num_cast = ta.num_movies
ORDER BY 
    rm.production_year DESC, 
    rm.title;
