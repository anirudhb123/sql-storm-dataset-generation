WITH RECURSIVE MovieChain AS (
    SELECT 
        mt.id AS movie_chain_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS depth
    FROM 
        title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        mt.id AS movie_chain_id,
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mc.depth + 1
    FROM 
        MovieChain mc
    JOIN 
        movie_link ml ON mc.linked_movie_id = ml.movie_id
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mc.depth < 5  -- limit chain depth
),
ActorData AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        ARRAY_AGG(DISTINCT title.title) AS movie_list
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        title ON ci.movie_id = title.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name
    HAVING 
        COUNT(ci.movie_id) > 2 -- actors with more than 2 movies
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        mp.info AS production_info
    FROM 
        title m
    LEFT JOIN 
        movie_info mp ON m.id = mp.movie_id
    WHERE 
        mp.info_type_id = (SELECT id FROM info_type WHERE info = 'production company')
)
SELECT 
    m.id AS movie_id,
    m.title AS movie_title,
    m.production_year,
    ad.actor_name,
    ad.movie_count,
    mv.production_info,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    mc.depth AS linked_movie_depth
FROM 
    title m
LEFT JOIN 
    MovieInfo mv ON m.id = mv.movie_id
LEFT JOIN 
    ActorData ad ON m.id IN (SELECT movie_id FROM cast_info ci WHERE ci.person_id IN (SELECT person_id FROM aka_name WHERE name = ad.actor_name))
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    MovieChain mc ON m.id = mc.movie_chain_id
WHERE 
    m.production_year >= 2000
ORDER BY 
    m.production_year DESC, ad.movie_count DESC;
