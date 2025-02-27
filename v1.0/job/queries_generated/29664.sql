WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER(PARTITION BY t.kind_id ORDER BY m.rating DESC) AS rank
    FROM 
        title t
    JOIN 
        movie_info mi ON t.id = mi.movie_id
    JOIN 
        movie_info_idx m ON mi.movie_id = m.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') AND
        m.info IS NOT NULL
),
TopRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        kind_id
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorMovieRelation AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        cm.movie_id,
        tm.title,
        tm.production_year
    FROM 
        cast_info cm
    JOIN 
        aka_name ak ON cm.person_id = ak.person_id
    JOIN 
        TopRankedMovies tm ON cm.movie_id = tm.movie_id
)
SELECT 
    amr.actor_name,
    amr.title,
    amr.production_year,
    kt.kind AS movie_kind,
    COUNT(*) AS total_appearances
FROM 
    ActorMovieRelation amr
JOIN 
    kind_type kt ON amr.kind_id = kt.id
GROUP BY 
    amr.actor_name, amr.title, amr.production_year, kt.kind
ORDER BY 
    total_appearances DESC;

