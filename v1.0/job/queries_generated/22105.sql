WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompletedCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS actors_with_notes
    FROM 
        complete_cast cc
    JOIN 
        cast_info c ON cc.movie_id = c.movie_id
    GROUP BY 
        cc.movie_id
),
HighActorsMovies AS (
    SELECT 
        rc.movie_id,
        rc.title,
        rc.production_year,
        rc.rank_within_year,
        cc.total_actors,
        cc.actors_with_notes,
        CASE 
            WHEN cc.total_actors >= 5 THEN 'Popular'
            WHEN cc.total_actors BETWEEN 3 AND 4 THEN 'Average'
            ELSE 'Less-known'
        END AS popularity_category
    FROM 
        RankedMovies rc
    LEFT JOIN 
        CompletedCast cc ON rc.movie_id = cc.movie_id
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    h.rank_within_year,
    h.total_actors,
    h.actors_with_notes,
    h.popularity_category,
    COALESCE(NULLIF(h.actors_with_notes, 0), 'No Actors with Notes') AS notes_info,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
FROM 
    HighActorsMovies h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    h.popularity_category <> 'Less-known'
GROUP BY 
    h.movie_id, h.title, h.production_year, h.rank_within_year, h.total_actors, h.actors_with_notes, h.popularity_category
ORDER BY 
    h.production_year DESC, h.rank_within_year ASC
FETCH FIRST 10 ROWS ONLY;
