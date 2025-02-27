WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COALESCE(
            (SELECT COUNT(*)
             FROM cast_info ci
             WHERE ci.movie_id = m.id), 0) AS cast_count,
        m.kind_id,
        1 AS level
    FROM title m
    WHERE m.production_year >= 2000

    UNION ALL

    SELECT 
        t.id,
        t.title,
        t.production_year,
        COALESCE(
            (SELECT COUNT(*)
             FROM cast_info ci
             WHERE ci.movie_id = t.id), 0) AS cast_count,
        t.kind_id,
        mh.level + 1
    FROM title t
    JOIN movie_link ml ON ml.linked_movie_id = t.id
    JOIN MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.cast_count,
        mh.level,
        RANK() OVER (PARTITION BY mh.kind_id ORDER BY mh.cast_count DESC) AS rank_per_kind
    FROM MovieHierarchy mh
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.level,
        rm.rank_per_kind,
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ')
         FROM movie_keyword mk
         JOIN keyword k ON mk.keyword_id = k.id
         WHERE mk.movie_id = rm.movie_id) AS keywords,
        (SELECT STRING_AGG(DISTINCT c.name, ', ')
         FROM complete_cast cc
         JOIN aka_title kt ON cc.movie_id = kt.movie_id
         JOIN aka_name c ON cc.subject_id = c.person_id
         WHERE kt.id = rm.movie_id) AS cast_names
    FROM RankedMovies rm
    WHERE rm.rank_per_kind <= 3
)
SELECT 
    md.movie_id,
    md.movie_title,
    md.production_year,
    md.cast_count,
    md.keywords,
    md.cast_names,
    CASE 
        WHEN md.level > 1 THEN 'Linked Movie'
        ELSE 'Standalone Movie'
    END AS movie_type
FROM MovieDetails md
WHERE md.production_year >= (SELECT MAX(production_year) - 5 FROM title)
ORDER BY md.production_year DESC, md.cast_count DESC;
