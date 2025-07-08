
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        1 AS depth,
        ARRAY_CONSTRUCT(m.id) AS path
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL  

    UNION ALL

    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        mh.depth + 1,
        ARRAY_CAT(mh.path, ARRAY_CONSTRUCT(m.id))
    FROM
        aka_title m
    JOIN MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        LISTAGG(DISTINCT CAST(c.person_id AS TEXT), ', ') WITHIN GROUP (ORDER BY c.person_id) AS cast_members,
        COUNT(DISTINCT kc.keyword_id) AS keyword_count,
        COALESCE(mt.kind, 'Unknown') AS movie_type,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.production_year DESC) AS rank,
        CASE 
            WHEN m.production_year IS NULL THEN 'Year Not Available'
            ELSE CAST(m.production_year AS TEXT)
        END AS production_year_display
    FROM
        aka_title m
    LEFT JOIN
        cast_info c ON m.id = c.movie_id
    LEFT JOIN
        movie_keyword kc ON m.id = kc.movie_id
    LEFT JOIN
        kind_type mt ON m.kind_id = mt.id
    GROUP BY
        m.id, m.title, m.production_year, mt.kind
)
SELECT
    mh.movie_id,
    mh.movie_title,
    md.production_year_display,
    md.cast_members,
    md.keyword_count,
    md.movie_type,
    mh.depth
FROM
    MovieHierarchy mh
JOIN 
    MovieDetails md ON mh.movie_id = md.movie_id
WHERE 
    md.keyword_count > 0
ORDER BY 
    mh.depth, 
    md.keyword_count DESC, 
    md.production_year DESC;
