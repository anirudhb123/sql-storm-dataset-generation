
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('feature', 'short'))
), ActorMovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info AS c
    JOIN 
        RankedMovies AS rm ON c.movie_id = rm.movie_id
    GROUP BY 
        c.person_id
), ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        ac.movie_count,
        RANK() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        aka_name AS a
    JOIN 
        ActorMovieCount AS ac ON a.person_id = ac.person_id
), TopActors AS (
    SELECT 
        name,
        movie_count,
        actor_rank
    FROM 
        ActorDetails
    WHERE 
        actor_rank <= 10
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), FullMovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COALESCE(a.name, 'Uncredited') AS actor_name,
        am.movie_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        MovieKeywords AS mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        cast_info AS c ON rm.movie_id = c.movie_id
    LEFT JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        ActorMovieCount AS am ON c.person_id = am.person_id
    WHERE 
        rm.rank_within_year = 1
)

SELECT 
    fmd.title,
    fmd.production_year,
    fmd.keywords,
    tv.name AS actor_name,
    tv.movie_count
FROM 
    FullMovieDetails AS fmd
JOIN 
    TopActors AS tv ON fmd.actor_name = tv.name
WHERE 
    fmd.production_year >= 2000
AND 
    fmd.keywords IS NOT NULL
ORDER BY 
    fmd.production_year DESC, 
    tv.movie_count DESC
LIMIT 20;
