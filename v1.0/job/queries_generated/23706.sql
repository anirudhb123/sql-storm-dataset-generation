WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        ARRAY[mt.title] AS title_path,
        1 AS depth
    FROM aka_title mt
    WHERE mt.production_year > 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        mh.title_path || m.title,
        mh.depth + 1
    FROM movie_link ml
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
    WHERE m.production_year <= 2000 AND mh.depth < 5
),
RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        row_number() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) AS cast_count
    FROM aka_title m
    LEFT JOIN cast_info c ON c.movie_id = m.id   -- Including outer join to allow movies with no cast
),
SubqueryWithNulls AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(k.keyword, 'No keyword') AS keyword,
        SUM(COALESCE(ki.info, 0)::int) AS total_info
    FROM RankedMovies m
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_info ki ON ki.movie_id = m.movie_id
    WHERE m.cast_count > 0
    GROUP BY m.id, k.keyword
),
FinalResult AS (
    SELECT 
        h.title_path[1] AS root_movie,
        h.title_path[depth] AS current_movie,
        r.title_rank,
        r.cast_count,
        COALESCE(s.total_info, 0) AS total_info
    FROM MovieHierarchy h
    JOIN RankedMovies r ON h.movie_id = r.movie_id
    LEFT JOIN SubqueryWithNulls s ON r.movie_id = s.movie_id
)
SELECT 
    DISTINCT f.root_movie AS "Root Movie",
    f.current_movie AS "Current Movie",
    f.title_rank AS "Title Rank",
    f.cast_count AS "Number of Cast Members",
    f.total_info AS "Total Movie Info"
FROM FinalResult f
WHERE 
    f.cast_count IS NOT NULL
    AND (f.total_info > 10 OR f.total_info IS NULL)
ORDER BY 
    f.title_rank DESC,
    f.current_movie ASC;
