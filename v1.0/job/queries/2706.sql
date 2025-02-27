WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        kt.kind
    FROM 
        RankedMovies rm
    JOIN 
        kind_type kt ON rm.kind_id = kt.id
    WHERE 
        rm.rank <= 5
),
ActorMovieCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        TopMovies tm ON ci.movie_id IN (SELECT id FROM aka_title WHERE title = tm.title)
    GROUP BY 
        ci.person_id
),
FilteredActors AS (
    SELECT 
        a.id,
        a.name,
        amc.movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > 3
)
SELECT 
    fa.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year AS year,
    kt.kind AS movie_kind
FROM 
    FilteredActors fa
JOIN 
    cast_info ci ON fa.id = ci.person_id
JOIN 
    aka_title tm ON ci.movie_id = tm.id
JOIN 
    kind_type kt ON tm.kind_id = kt.id
WHERE 
    tm.production_year BETWEEN 2000 AND 2023
    AND kt.kind IS NOT NULL
ORDER BY 
    fa.name, tm.production_year DESC;
