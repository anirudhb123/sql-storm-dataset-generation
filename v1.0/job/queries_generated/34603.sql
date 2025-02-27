WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.depth,
        COALESCE(mci.company_id, -1) AS company_id,
        COUNT(cast.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors
    FROM MovieHierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info cast ON cc.subject_id = cast.person_id
    LEFT JOIN movie_companies mci ON mh.movie_id = mci.movie_id
    LEFT JOIN aka_name a ON cast.person_id = a.person_id
    GROUP BY mh.movie_id, mh.title, mh.production_year, mh.depth, company_id
),

MoviesWithRank AS (
    SELECT 
        fm.*,
        RANK() OVER (PARTITION BY fm.company_id ORDER BY fm.cast_count DESC) AS rank_within_company
    FROM FilteredMovies fm
)

SELECT 
    mwr.movie_id,
    mwr.title,
    mwr.production_year,
    mwr.depth,
    mwr.cast_count,
    mwr.actors,
    ct.kind AS company_type,
    ci.note AS company_note
FROM MoviesWithRank mwr
LEFT JOIN movie_companies mc ON mwr.movie_id = mc.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
LEFT JOIN movie_info mi ON mwr.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'production')
LEFT JOIN movie_info_idx mi_idx ON mwr.movie_id = mi_idx.movie_id
LEFT JOIN person_info pi ON mwr.movie_id = pi.person_id
WHERE mwr.rank_within_company <= 3
  AND mwr.cast_count > 0
  AND cn.country_code IS NOT NULL
ORDER BY mwr.production_year DESC, mwr.cast_count DESC;
