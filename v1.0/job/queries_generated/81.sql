WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id) AS movie_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
SelectedActors AS (
    SELECT 
        ak.name AS actor_name,
        pm.id AS person_id,
        amc.movie_count,
        COALESCE(mk.keyword_count, 0) AS keyword_count
    FROM 
        aka_name ak
    JOIN 
        person_info pi ON ak.person_id = pi.person_id
    LEFT JOIN 
        ActorMovieCount amc ON ak.person_id = amc.person_id
    JOIN 
        name nm ON ak.person_id = nm.imdb_id
    LEFT JOIN 
        MovieKeywords mk ON nm.imdb_id = mk.movie_id
    WHERE 
        pi.info LIKE '%Academy Award%'
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        sa.actor_name,
        sa.movie_count,
        sa.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        SelectedActors sa ON rm.movie_id = sa.movie_count
    WHERE 
        rm.movie_rank <= 10
)
SELECT 
    tm.title,
    tm.production_year,
    tm.actor_name,
    tm.movie_count,
    tm.keyword_count,
    CASE 
        WHEN tm.keyword_count > 5 THEN 'Popular'
        WHEN tm.keyword_count IS NULL THEN 'Unknown'
        ELSE 'Less Popular'
    END AS popularity
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, 
    tm.title;
