WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        0 AS depth,
        NULL AS parent_movie_id
    FROM 
        aka_title t
    JOIN 
        title m ON t.movie_id = m.id
    WHERE 
        m.production_year > 2000

    UNION ALL 

    SELECT 
        mh.movie_id,
        t.title,
        mh.production_year,
        mh.depth + 1,
        mh.movie_id AS parent_movie_id
    FROM 
        MovieHierarchy mh
    JOIN 
        title t ON mh.movie_id = t.episode_of_id
    WHERE 
        t.season_nr IS NOT NULL
),

AggregatedData AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        AVG(m.production_year) OVER (PARTITION BY mh.production_year) AS avg_release_year,
        STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS cast_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON mh.movie_id = c.movie_id
    LEFT JOIN 
        aka_name cn ON c.person_id = cn.person_id
    WHERE 
        cn.name IS NOT NULL AND c.note IS NULL
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),

FinalOutput AS (
    SELECT 
        ad.title,
        ad.production_year,
        ad.actor_count,
        ad.avg_release_year,
        COALESCE(ad.cast_names, 'No Cast') AS cast_names
    FROM 
        AggregatedData ad
    WHERE 
        ad.actor_count > 0
    ORDER BY 
        ad.production_year DESC,
        ad.actor_count DESC
)

SELECT 
    ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY actor_count DESC) AS rank,
    title,
    production_year,
    actor_count,
    avg_release_year,
    cast_names
FROM 
    FinalOutput
WHERE 
    production_year BETWEEN 2000 AND 2023
AND EXISTS (
    SELECT 1 
    FROM movie_keyword mk 
    WHERE mk.movie_id = FinalOutput.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Action%')
)
UNION ALL
SELECT 
    NULL AS rank,
    'No Titles' AS title,
    NULL AS production_year,
    0 AS actor_count,
    NULL AS avg_release_year,
    string_agg(DISTINCT cn.name, ', ') AS cast_names
FROM 
    aka_name cn
WHERE 
    cn.name NOT LIKE '%Anonymous%' 
AND NOT EXISTS (
    SELECT 1 
    FROM AggregatedData ad 
    WHERE ad.cast_names LIKE '%' || cn.name || '%'
)
GROUP BY 
    cn.name
ORDER BY 
    rank NULLS LAST
LIMIT 10;
