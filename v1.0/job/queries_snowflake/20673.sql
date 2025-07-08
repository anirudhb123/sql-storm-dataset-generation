
WITH RecursiveMovieCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        t.title,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
    WHERE 
        ak.name IS NOT NULL
),
MovieInfo AS (
    SELECT 
        mv.id AS movie_id,
        MIN(mv.production_year) AS earliest_year,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords_list
    FROM 
        aka_title mv
    LEFT JOIN 
        movie_keyword mk ON mv.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mv.id
),
ActorsCount AS (
    SELECT 
        movie_id,
        COUNT(*) AS actor_count
    FROM 
        RecursiveMovieCast
    GROUP BY 
        movie_id
),
TopMovies AS (
    SELECT 
        m.movie_id,
        m.earliest_year,
        m.keywords_list,
        ac.actor_count,
        RANK() OVER (ORDER BY ac.actor_count DESC, m.earliest_year ASC) AS movie_rank
    FROM 
        MovieInfo m
    JOIN 
        ActorsCount ac ON m.movie_id = ac.movie_id
)
SELECT 
    tm.movie_id,
    tm.earliest_year,
    tm.keywords_list,
    tm.actor_count,
    rc.actor_name,
    rc.actor_order
FROM 
    TopMovies tm
LEFT JOIN 
    RecursiveMovieCast rc ON tm.movie_id = rc.movie_id
WHERE 
    tm.movie_rank <= 10
ORDER BY 
    tm.actor_count DESC, 
    tm.earliest_year ASC,
    rc.actor_order ASC
;
