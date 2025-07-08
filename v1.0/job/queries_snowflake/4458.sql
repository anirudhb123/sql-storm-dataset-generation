
WITH RankedTitles AS (
    SELECT
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM
        title t
    WHERE
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'No Info') AS movie_info,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    LEFT JOIN
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY
        m.id, m.title, mi.info
),
CastDetails AS (
    SELECT 
        c.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS cast_names,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
)
SELECT
    mt.title_id,
    mt.title,
    mt.production_year,
    COALESCE(cd.cast_names, 'No Cast') AS cast_names,
    md.movie_info,
    md.keyword_count,
    mt.rank
FROM
    RankedTitles mt
LEFT JOIN
    MovieDetails md ON mt.title_id = md.movie_id
LEFT JOIN
    CastDetails cd ON mt.title_id = cd.movie_id
WHERE
    (md.keyword_count > 2 OR cd.total_cast > 3)
ORDER BY
    mt.production_year DESC,
    mt.rank ASC
LIMIT 100;
