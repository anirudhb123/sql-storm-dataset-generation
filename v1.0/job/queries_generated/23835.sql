WITH RecursiveMovieLinks AS (
    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        1 AS link_depth
    FROM 
        movie_link ml
    WHERE 
        ml.movie_id IS NOT NULL

    UNION ALL

    SELECT 
        ml.movie_id,
        ml.linked_movie_id,
        rml.link_depth + 1
    FROM 
        movie_link ml
    JOIN 
        RecursiveMovieLinks rml ON ml.movie_id = rml.linked_movie_id
    WHERE 
        rml.link_depth < 5
), 

MovieGenres AS (
    SELECT 
        mt.movie_id,
        kt.keyword AS genre
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
), 

CompleteCastInfo AS (
    SELECT 
        cc.movie_id,
        a.name AS actor_name,
        rc.role AS role_name,
        COUNT(*) OVER (PARTITION BY cc.movie_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY cc.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rc ON ci.role_id = rc.id
), 

MoviesWithMaxCast AS (
    SELECT 
        movie_id,
        MAX(total_cast) AS max_cast
    FROM 
        CompleteCastInfo
    GROUP BY 
        movie_id
)

SELECT 
    mt.title AS movie_title,
    ARRAY_AGG(DISTINCT mg.genre) AS genres,
    cci.actor_name,
    cci.role_name,
    ml.linked_movie_id,
    COALESCE(mwc.max_cast, 0) AS max_cast,
    CASE 
        WHEN cci.actor_rank <= 2 THEN 'Leading Actor'
        WHEN cci.actor_rank IS NULL THEN 'Unknown'
        ELSE 'Supporting'
    END AS actor_status
FROM 
    aka_title mt
LEFT JOIN 
    MovieGenres mg ON mt.id = mg.movie_id
LEFT JOIN 
    CompleteCastInfo cci ON mt.id = cci.movie_id
LEFT JOIN 
    RecursiveMovieLinks ml ON mt.id = ml.movie_id
LEFT JOIN 
    MoviesWithMaxCast mwc ON mt.id = mwc.movie_id
WHERE 
    mt.production_year IS NOT NULL 
    AND (mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%movie%') 
         OR mt.kind_id IS NULL)
    AND (mwc.max_cast > 5 OR cci.role_name IS NOT NULL)
GROUP BY 
    mt.title, cci.actor_name, cci.role_name, ml.linked_movie_id, mwc.max_cast, cci.actor_rank
ORDER BY 
    max_cast DESC, movie_title ASC NULLS LAST;
