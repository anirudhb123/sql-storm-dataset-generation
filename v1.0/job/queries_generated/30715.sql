WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM title AS t
    WHERE t.production_year IS NOT NULL

    UNION ALL

    SELECT 
        linked_movie.movie_id,
        l.title AS movie_title,
        linked_movie.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM movie_link AS linked_movie
    JOIN title AS l ON linked_movie.linked_movie_id = l.id
    JOIN MovieHierarchy AS mh ON mh.movie_id = linked_movie.movie_id
)
SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    mh.level,
    COALESCE(cast_info.count_cast, 0) AS total_cast,
    COALESCE(info.count_info, 0) AS total_info,
    COALESCE(keywords.keyword_list, '') AS keywords_used
FROM MovieHierarchy AS mh
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS count_cast
    FROM cast_info 
    GROUP BY movie_id
) AS cast_info ON mh.movie_id = cast_info.movie_id
LEFT JOIN (
    SELECT 
        movie_id, 
        COUNT(*) AS count_info 
    FROM movie_info 
    GROUP BY movie_id
) AS info ON mh.movie_id = info.movie_id
LEFT JOIN (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM movie_keyword AS mk
    JOIN keyword AS k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
) AS keywords ON mh.movie_id = keywords.movie_id
WHERE mh.production_year >= 2000
ORDER BY mh.level, mh.movie_title ASC;

