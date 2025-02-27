WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM
        MovieHierarchy mh
    JOIN
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN
        aka_title at ON ml.linked_movie_id = at.id
    WHERE
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
GenreRankings AS (
    SELECT
        ki.keyword,
        COUNT(mk.movie_id) AS movie_count
    FROM
        movie_keyword mk
    JOIN
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY
        ki.keyword
    ORDER BY
        movie_count DESC
    LIMIT 10
),
TopMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        DENSE_RANK() OVER (ORDER BY mh.depth) AS movie_rank
    FROM
        MovieHierarchy mh
    WHERE
        mh.depth <= 3
),
FinalResults AS (
    SELECT
        tm.title,
        tm.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors_names,
        COUNT(DISTINCT g.keyword) AS genre_count
    FROM
        TopMovies tm
    LEFT JOIN
        complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN
        keyword g ON mk.keyword_id = g.id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY
        tm.title, tm.production_year
)
SELECT
    fr.title,
    fr.production_year,
    fr.cast_count,
    fr.actors_names,
    fr.genre_count,
    CASE 
        WHEN fr.genre_count > 0 THEN 'Genre Present'
        ELSE 'No Genre'
    END AS genre_status
FROM
    FinalResults fr
WHERE
    fr.cast_count > 0
ORDER BY
    fr.production_year DESC,
    fr.cast_count DESC
LIMIT 20;
