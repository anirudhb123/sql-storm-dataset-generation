WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(c.kind, 'Unknown') AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        kind_type c ON a.kind_id = c.id
),
ActorMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.movie_id) OVER (PARTITION BY ak.person_id) AS total_movies_by_actor
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.id
),
MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        COUNT(DISTINCT m.id) AS company_count,
        MAX(CASE WHEN m.note IS NOT NULL THEN 'Has Note' ELSE 'No Note' END) AS note_status
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies m ON a.id = m.movie_id
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        a.title, a.production_year
),
Benchmark AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.movie_kind,
        am.actor_name,
        am.total_movies_by_actor,
        md.actors,
        md.company_count,
        md.note_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.title = am.movie_title AND rm.production_year = am.production_year
    LEFT JOIN 
        MovieDetails md ON rm.title = md.movie_title AND rm.production_year = md.production_year
)
SELECT 
    *
FROM 
    Benchmark
WHERE 
    rank_per_year <= 5
ORDER BY 
    production_year DESC, movie_kind, actor_name;
