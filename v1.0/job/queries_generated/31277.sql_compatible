
WITH RECURSIVE MovieChain AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS chain_length
    FROM 
        aka_title mt
    WHERE 
        mt.production_year = 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        mt.title AS movie_title,
        mc.chain_length + 1
    FROM 
        MovieChain mc
    JOIN 
        movie_link ml ON mc.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mt.production_year = 2023
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(ci.nr_order) AS max_order
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        ai.title AS movie_title,
        ai.production_year,
        ai.id AS movie_id,
        COALESCE(ci.total_cast, 0) AS total_cast,
        COALESCE(cd.chain_length, 0) AS movie_chain_length
    FROM 
        aka_title ai
    LEFT JOIN 
        CastDetails ci ON ai.id = ci.movie_id
    LEFT JOIN 
        MovieChain cd ON ai.id = cd.movie_id
    WHERE 
        ai.production_year = 2023
)
SELECT 
    mi.movie_title,
    mi.production_year,
    mi.total_cast,
    mi.movie_chain_length,
    CASE 
        WHEN mi.movie_chain_length > 0 THEN 'Linked Movie Exists'
        ELSE 'No Linked Movie'
    END AS movie_link_status
FROM 
    MovieInfo mi
ORDER BY 
    mi.production_year DESC, 
    mi.movie_title;
