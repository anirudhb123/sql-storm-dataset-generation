WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        mt.kind AS movie_kind,
        1 AS level
    FROM 
        aka_title m
    LEFT JOIN 
        kind_type mt ON m.kind_id = mt.id

    UNION ALL

    SELECT 
        mh.movie_id,
        mt.title,
        COALESCE(mt.production_year, 0),
        kt.kind AS movie_kind,
        level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        kind_type kt ON mt.kind_id = kt.id
    WHERE 
        mh.level < 5
),
FilteredMovies AS (
    SELECT 
        mv.movie_id, 
        mv.title,
        mv.production_year,
        mv.movie_kind,
        COUNT(DISTINCT c.person_id) AS cast_count,
        AVG(CASE WHEN pc.info IS NULL THEN 0 ELSE 1 END) AS avg_person_info
    FROM 
        MovieHierarchy mv
    LEFT JOIN 
        complete_cast cc ON mv.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        person_info pc ON c.person_id = pc.person_id
    WHERE 
        mv.production_year > 2000 
        AND mv.movie_kind IS NOT NULL
    GROUP BY 
        mv.movie_id, mv.title, mv.production_year, mv.movie_kind
),
RankedMovies AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY movie_kind ORDER BY cast_count DESC, production_year DESC) AS rank_per_kind
    FROM 
        FilteredMovies
)
SELECT 
    rm.title,
    rm.production_year,
    rm.movie_kind,
    rm.cast_count,
    CASE 
        WHEN rm.avg_person_info > 0.5 THEN 'Highly Informative'
        ELSE 'Less Informative'
    END AS info_rating,
    COALESCE(NULLIF(rm.production_year, 0), 'Unknown Year') AS effective_year
FROM 
    RankedMovies rm
WHERE 
    rm.rank_per_kind <= 10
    AND (rm.cast_count > 5 OR rm.movie_kind LIKE '%Drama%')
ORDER BY 
    rm.movie_kind, rm.cast_count DESC;
