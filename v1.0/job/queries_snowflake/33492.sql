
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        CAST(NULL AS integer) AS parent_movie_id,
        1 AS level
    FROM title t
    WHERE t.production_year >= 2000  
    UNION ALL
    SELECT
        ml.linked_movie_id AS movie_id,
        th.title,
        th.production_year,
        mh.movie_id AS parent_movie_id,
        mh.level + 1
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title th ON ml.linked_movie_id = th.id
    WHERE mh.level < 3  
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS total_cast,
        SUM(CASE WHEN ci.nr_order IS NULL THEN 1 ELSE 0 END) AS unnumbered_cast
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        mc.total_cast,
        mc.unnumbered_cast,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = mh.movie_id) AS keyword_count
    FROM MovieHierarchy mh
    LEFT JOIN MovieCast mc ON mh.movie_id = mc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.total_cast,
    md.unnumbered_cast,
    md.keyword_count,
    COALESCE(CAST(md.total_cast AS FLOAT) / NULLIF(md.unnumbered_cast, 0), 0) AS cast_ratio,
    CASE 
        WHEN md.production_year < 2010 THEN 'Pre-2010'
        ELSE 'Post-2010'
    END AS period
FROM MovieDetails md
WHERE md.total_cast > 0
ORDER BY md.production_year DESC, md.keyword_count DESC;
