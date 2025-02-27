WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        h.movie_id,
        h.title,
        h.production_year,
        h.level,
        ROW_NUMBER() OVER (PARTITION BY h.kind_id ORDER BY h.production_year DESC) AS rn
    FROM 
        MovieHierarchy h
),
MovieCast AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS num_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        c.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mc.num_cast, 0) AS total_cast,
    rm.level,
    CASE 
        WHEN rm.level = 1 THEN 'Main Movie'
        ELSE 'Episode'
    END AS movie_type,
    CASE 
        WHEN rm.rn <= 10 THEN 'Top 10' 
        ELSE 'Not Top 10' 
    END AS rank_status,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, mc.num_cast, rm.level, rm.rn
ORDER BY 
    rm.production_year DESC, rm.level;
