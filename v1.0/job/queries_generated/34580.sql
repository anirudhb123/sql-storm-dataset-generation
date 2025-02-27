WITH RECURSIVE MovieHierarchy AS (
    -- CTE to get the hierarchical structure of movies based on episodes
    SELECT 
        id, 
        title, 
        production_year, 
        kind_id, 
        episode_of_id,
        1 AS level
    FROM
        aka_title
    WHERE
        episode_of_id IS NULL

    UNION ALL

    SELECT 
        at.id, 
        at.title, 
        at.production_year, 
        at.kind_id, 
        at.episode_of_id,
        mh.level + 1
    FROM
        aka_title at
    JOIN 
        MovieHierarchy mh ON at.episode_of_id = mh.id
),
RankedMovies AS (
    -- CTE to rank movies by their production year and count of cast
    SELECT 
        m.id, 
        m.title, 
        m.production_year, 
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
MovieInformation AS (
    -- CTE to gather additional info using string operations
    SELECT 
        m.id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No Information') AS additional_info,
        CASE 
            WHEN m.production_year >= 2000 THEN 'Modern Era'
            ELSE 'Classic Era'
        END AS era_type
    FROM
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = 1
)
SELECT 
    mh.title AS episode_title,
    mh.production_year AS episode_year,
    COUNT(DISTINCT ci.person_id) AS total_cast,
    MAX(mi.additional_info) AS info,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count,
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS avg_order
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON mh.id = ci.movie_id
LEFT JOIN 
    MovieInformation mi ON mi.id = mh.id
WHERE 
    mh.level > 1 -- focusing only on episodes
GROUP BY 
    mh.id, mh.title, mh.production_year
ORDER BY 
    mh.production_year DESC, total_cast DESC
LIMIT 10;
