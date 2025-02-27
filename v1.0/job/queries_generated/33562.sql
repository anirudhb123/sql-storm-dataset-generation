WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON ml.linked_movie_id = t.id
),
RankedMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        mh.kind_id,
        COALESCE(ki.info, '-') AS info,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank_level
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    LEFT JOIN 
        info_type ki ON mi.info_type_id = ki.id
    WHERE 
        mh.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.info,
    cd.total_cast,
    cd.cast_names,
    CASE 
        WHEN rm.rank_level <= 10 THEN 'Top 10'
        ELSE 'Below Top 10'
    END AS rank_category
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    (rm.production_year = 2023 AND cd.total_cast IS NOT NULL) OR
    (rm.production_year < 2023 AND cd.total_cast IS NULL)
ORDER BY 
    rm.production_year, 
    rm.rank_level;
