WITH MovieDetails AS (
    SELECT
        t.title,
        t.production_year,
        t.kind_id,
        COALESCE(k.keyword, 'No Keywords') AS keyword,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE
        t.production_year IS NOT NULL
        AND t.kind_id IS NOT NULL
    GROUP BY
        t.title, t.production_year, t.kind_id, k.keyword
),
AverageCast AS (
    SELECT
        AVG(cast_count) AS avg_cast_count
    FROM
        MovieDetails
),
TitleWithAboveAvgCast AS (
    SELECT
        m.title,
        m.production_year,
        m.keyword,
        m.cast_count
    FROM
        MovieDetails m
    JOIN AverageCast a ON m.cast_count > a.avg_cast_count
),
RelatedMovies AS (
    SELECT
        ml.movie_id,
        ml.linked_movie_id,
        ml.link_type_id,
        lt.link AS link_type
    FROM
        movie_link ml
    JOIN link_type lt ON ml.link_type_id = lt.id
)
SELECT
    tw.title,
    tw.production_year,
    tw.keyword,
    r.linked_movie_id,
    r.link_type,
    CASE
        WHEN r.linked_movie_id IS NULL THEN 'No related movies'
        ELSE 'Related movie exists'
    END AS relationship_status
FROM
    TitleWithAboveAvgCast tw
LEFT JOIN RelatedMovies r ON tw.production_year = (SELECT MAX(production_year) FROM aka_title WHERE id = r.linked_movie_id)
ORDER BY
    tw.production_year DESC,
    tw.title ASC;
