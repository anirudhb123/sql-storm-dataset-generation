WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 as depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        depth + 1
    FROM 
        MovieCTE c
    JOIN 
        movie_link ml ON c.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        c.depth < 3
),

AggregatedData AS (
    SELECT 
        a.id AS actor_id,
        ak.name AS actor_name,
        COUNT(DISTINCT mc.movie_id) AS movies_count,
        COUNT(DISTINCT mk.keyword_id) AS keywords_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords_list
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    LEFT JOIN 
        movie_keyword mk ON ci.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    LEFT JOIN 
        MovieCTE m ON ci.movie_id = m.movie_id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Director')
        AND ak.name IS NOT NULL
        AND m.depth IS NOT NULL
    GROUP BY 
        ak.name, a.id
),

FinalSelection AS (
    SELECT 
        a.actor_id,
        a.actor_name,
        a.movies_count,
        a.keywords_count,
        RANK() OVER (ORDER BY a.movies_count DESC) AS rank_position
    FROM 
        AggregatedData a
    WHERE 
        a.movies_count > 0
)

SELECT 
    f.actor_id,
    f.actor_name,
    f.movies_count,
    f.keywords_count,
    f.rank_position,
    CASE 
        WHEN f.rank_position <= 10 THEN 'Top Actor'
        WHEN f.rank_position BETWEEN 11 AND 50 THEN 'Mid Actor'
        ELSE 'Newcomer'
    END AS category
FROM 
    FinalSelection f
WHERE 
    f.keywords_count > 5 
ORDER BY 
    f.rank_position;
