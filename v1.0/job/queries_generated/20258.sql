WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

LatestAwards AS (
    SELECT 
        movie_id, 
        COUNT(*) AS award_count 
    FROM 
        movie_info 
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
    GROUP BY 
        movie_id
),

AwardWinningMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(la.award_count, 0) AS award_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        LatestAwards la ON rm.id = la.movie_id
    WHERE 
        rm.rank <= 5
),

TopActors AS (
    SELECT 
        a.name AS actor_name, 
        COUNT(c.id) AS movies_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        a.name
    HAVING 
        COUNT(c.id) > 10
)

SELECT 
    am.title,
    am.production_year,
    am.award_count,
    ta.actor_name,
    ta.movies_count
FROM 
    AwardWinningMovies am
LEFT JOIN 
    TopActors ta ON ta.movies_count = 5
WHERE 
    am.award_count > 0
ORDER BY 
    am.production_year DESC, 
    am.award_count DESC, 
    ta.movies_count DESC;

WITH MovieStats AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS distinct_actors,
        AVG(LENGTH(t.title)) AS avg_title_length
    FROM 
        aka_title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id
)

SELECT 
    ms.movie_id,
    ms.distinct_actors,
    ms.avg_title_length,
    CASE 
        WHEN ms.distinct_actors > 10 THEN 'Popular'
        WHEN ms.distinct_actors IS NULL THEN 'No Cast'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    MovieStats ms
WHERE 
    ms.avg_title_length IS NOT NULL 
    AND ms.avg_title_length > 10
ORDER BY 
    ms.distinct_actors DESC;

SELECT 
    ct.kind, 
    COUNT(mc.movie_id) AS movie_count
FROM 
    company_type ct
LEFT JOIN 
    movie_companies mc ON mc.company_type_id = ct.id
WHERE 
    mc.company_id IS NOT NULL
GROUP BY 
    ct.kind
HAVING 
    COUNT(mc.movie_id) > 0
ORDER BY 
    movie_count DESC;

