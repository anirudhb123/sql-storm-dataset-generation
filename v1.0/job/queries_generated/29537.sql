WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as year_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
PersonActorCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id
),
HighProfileActors AS (
    SELECT 
        pa.id AS person_id,
        an.name AS actor_name,
        pac.movie_count
    FROM 
        person_info pa
    JOIN 
        aka_name an ON pa.person_id = an.person_id
    JOIN 
        PersonActorCounts pac ON pa.id = pac.person_id
    WHERE 
        pac.movie_count > 10
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT an.name, ', ') AS actors
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        mi.title,
        mi.production_year,
        ROW_NUMBER() OVER (ORDER BY mi.production_year DESC) AS rank
    FROM 
        MovieInfo mi
    WHERE 
        mi.production_year >= 2000
)
SELECT 
    t.title,
    t.production_year,
    hp.actor_name,
    hp.movie_count
FROM 
    TopMovies t
JOIN 
    HighProfileActors hp ON hp.person_id IN (
        SELECT DISTINCT ci.person_id
        FROM cast_info ci
        WHERE ci.movie_id = t.movie_id
    )
WHERE 
    t.rank <= 20
ORDER BY 
    t.production_year DESC, hp.movie_count DESC;
