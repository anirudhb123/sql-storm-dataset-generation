WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title, 
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
),
AggregatedCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.level,
        ac.total_cast,
        ac.cast_names
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        AggregatedCast AS ac ON mh.movie_id = ac.movie_id
    WHERE
        mh.level <= 3 AND 
        (ac.total_cast IS NULL OR ac.total_cast >= 3)
),
RankedMovies AS (
    SELECT 
        fm.*,
        RANK() OVER (PARTITION BY fm.level ORDER BY fm.total_cast DESC NULLS LAST) AS rank
    FROM 
        FilteredMovies AS fm
)
SELECT 
    rm.title,
    rm.level,
    rm.total_cast,
    rm.cast_names,
    (SELECT COUNT(*) 
     FROM movie_keyword AS mk 
     JOIN keyword AS k ON mk.keyword_id = k.id 
     WHERE mk.movie_id = rm.movie_id AND k.keyword LIKE '%action%') AS action_keywords,
    COALESCE((SELECT MAX(CASE WHEN m.note IS NULL THEN 'No Note' ELSE m.note END) 
                FROM movie_info AS m 
                WHERE m.movie_id = rm.movie_id AND m.info_type_id = 1), 'No Info') AS movie_info
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank <= 5 AND
    (SELECT COUNT(*) FROM movie_info AS m WHERE m.movie_id = rm.movie_id) > 0
ORDER BY 
    rm.level, 
    rm.total_cast DESC;
