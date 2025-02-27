WITH RECURSIVE MovieHierarchy AS (
    SELECT mt.id AS movie_id, mt.title, 1 AS hierarchy_level, NULL::INTEGER AS parent_id
    FROM aka_title mt
    WHERE mt.production_year >= 2000

    UNION ALL

    SELECT mt.id AS movie_id, mt.title, mh.hierarchy_level + 1, mh.movie_id
    FROM aka_title mt
    JOIN movie_link ml ON mt.id = ml.linked_movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
AggregatedMovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.hierarchy_level,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords_aggregated,
        AVG(CASE WHEN mi.info_type_id = 1 THEN NULLIF(CAST(mi.info AS NUMERIC), 0) END) AS average_rating
    FROM MovieHierarchy mh
    LEFT JOIN complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN movie_info mi ON mh.movie_id = mi.movie_id
    GROUP BY mh.movie_id, mh.title, mh.hierarchy_level
),
FinalMovieData AS (
    SELECT 
        amd.movie_id,
        amd.title,
        amd.hierarchy_level,
        amd.total_cast,
        amd.cast_names,
        amd.keywords_aggregated,
        COALESCE(amd.average_rating, 'Not Rated') AS average_rating
    FROM AggregatedMovieData amd
    WHERE amd.total_cast > 0
)

SELECT 
    fmd.title,
    fmd.hierarchy_level,
    fmd.total_cast,
    fmd.cast_names,
    fmd.keywords_aggregated,
    fmd.average_rating,
    CASE 
        WHEN fmd.total_cast > 10 THEN 'Star-Studded'
        WHEN fmd.total_cast BETWEEN 5 AND 10 THEN 'Moderately Cast'
        ELSE 'Low Cast'
    END AS cast_assessment,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = fmd.movie_id)) AS unique_actors
FROM FinalMovieData fmd
WHERE NULLIF(fmd.keywords_aggregated, '') IS NOT NULL
ORDER BY fmd.hierarchy_level DESC, fmd.total_cast DESC;
