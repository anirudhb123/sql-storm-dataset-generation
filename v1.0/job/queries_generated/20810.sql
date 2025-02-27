WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank,
        COUNT(ci.person_id) AS total_actors
    FROM
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        AVG(COALESCE(m.production_year, 0)) FILTER (WHERE m.production_year IS NOT NULL) AS avg_production_year,
        SUM(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) AS pre_2000_movies
    FROM
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title m ON ci.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name
),
FilteredActors AS (
    SELECT 
        actor_name,
        movies_count,
        avg_production_year,
        pre_2000_movies
    FROM 
        ActorDetails
    WHERE 
        movies_count > 5
    AND 
        avg_production_year > 1995
),
CombinedData AS (
    SELECT 
        rm.title,
        rm.production_year,
        fa.actor_name,
        fa.movies_count,
        fa.pre_2000_movies
    FROM 
        RankedMovies rm
    INNER JOIN 
        FilteredActors fa ON rm.actor_rank <= 5
    WHERE 
        rm.total_actors > 0
)
SELECT 
    cd.title,
    cd.production_year,
    cd.actor_name,
    cd.movies_count,
    cd.pre_2000_movies,
    COALESCE(NULLIF(cd.pre_2000_movies, 0), 1) AS safe_pre_2000_movies
FROM 
    CombinedData cd
ORDER BY
    cd.production_year DESC,
    cd.movies_count DESC,
    cd.actor_name

