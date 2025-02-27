WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rn
    FROM
        aka_title m
    WHERE
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
CastCount AS (
    SELECT
        c.movie_id,
        COUNT(c.person_id) AS cast_size
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cc.cast_size, 0) AS cast_size
    FROM
        RankedMovies rm
    LEFT JOIN
        CastCount cc ON rm.movie_id = cc.movie_id
)
SELECT
    md.title,
    md.production_year,
    md.cast_size,
    (SELECT STRING_AGG(DISTINCT ak.name, ', ') 
     FROM aka_name ak 
     JOIN cast_info ci ON ak.person_id = ci.person_id 
     WHERE ci.movie_id = md.movie_id) AS cast_names,
    (SELECT COUNT(DISTINCT kc.keyword) 
     FROM movie_keyword mk 
     JOIN keyword kc ON mk.keyword_id = kc.id 
     WHERE mk.movie_id = md.movie_id) AS keyword_count
FROM
    MovieDetails md
WHERE
    md.cast_size > (
        SELECT AVG(cast_size) FROM CastCount
    )
ORDER BY
    md.production_year DESC,
    md.title ASC;
