WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRankings AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS film_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.id, a.name
),
FilteredMovies AS (
    SELECT 
        mt.movie_id,
        mt.title,
        COUNT(DISTINCT km.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword km ON mt.id = km.movie_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.movie_id, mt.title
    HAVING 
        COUNT(DISTINCT km.keyword_id) > 5
),
DistinctActors AS (
    SELECT DISTINCT 
        ci.person_id
    FROM 
        cast_info ci
    JOIN 
        aka_title at ON ci.movie_id = at.id
    WHERE 
        at.production_year < 2010
)

SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ar.actor_id,
    ar.name AS actor_name,
    ar.film_count,
    COALESCE(fm.keyword_count, 0) AS keyword_count,
    CASE 
        WHEN ar.actor_rank <= 10 THEN 'Top Actor'
        ELSE 'Supporting Actor'
    END AS actor_category
FROM 
    RankedTitles rt
JOIN 
    ActorRankings ar ON rt.title_id IN (
        SELECT ci.movie_id
        FROM cast_info ci
        WHERE ci.person_id IN (SELECT person_id FROM DistinctActors)
    )
LEFT JOIN 
    FilteredMovies fm ON rt.title_id = fm.movie_id
WHERE 
    rt.year_rank BETWEEN 1 AND 5
OR 
    (rt.production_year IS NULL AND rt.title IS NOT NULL)
ORDER BY 
    rt.production_year DESC, ar.film_count DESC;
