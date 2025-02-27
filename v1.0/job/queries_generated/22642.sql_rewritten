WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(ml.linked_movie_id, 0) AS linked_movie_id
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
),
AggregatedData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS cast_names,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count
    FROM 
        MovieHierarchy mh
    JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
),
FilteredData AS (
    SELECT 
        ad.movie_id,
        ad.title,
        ad.production_year,
        ad.cast_count,
        ad.keyword_count,
        ad.cast_names
    FROM 
        AggregatedData ad
    WHERE 
        ad.rank_by_cast_count <= 5 AND
        ad.keyword_count > 3
)
SELECT 
    fd.title,
    fd.production_year,
    fd.cast_count,
    fd.cast_names,
    CASE 
        WHEN fd.cast_count IS NULL THEN 'No Cast'
        WHEN fd.cast_count > 10 THEN 'Ensemble Cast'
        ELSE 'Limited Cast'
    END AS cast_description,
    (SELECT COUNT(*)
        FROM title t
        WHERE t.production_year = fd.production_year AND t.id <> fd.movie_id
    ) AS movie_count_same_year,
    (SELECT 
        STRING_AGG(DISTINCT ct.kind, ', ')
        FROM movie_companies mc
        JOIN company_type ct ON mc.company_type_id = ct.id
        WHERE mc.movie_id = fd.movie_id
    ) AS company_types
FROM 
    FilteredData fd
ORDER BY 
    fd.production_year DESC, fd.cast_count DESC;