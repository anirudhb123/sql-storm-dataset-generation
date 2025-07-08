
WITH RankedMovies AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS cast_rank
    FROM
        aka_title mt
    JOIN
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY
        mt.id, mt.title, mt.production_year, mt.kind_id
),
FilteredMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.kind_id,
        CASE 
            WHEN rm.kind_id IN (SELECT DISTINCT kind_id FROM kind_type WHERE kind ILIKE 'drama%') THEN 'Drama'
            WHEN rm.kind_id IN (SELECT DISTINCT kind_id FROM kind_type WHERE kind ILIKE 'comedy%') THEN 'Comedy'
            ELSE 'Other'
        END AS movie_genre
    FROM
        RankedMovies rm
    WHERE
        rm.cast_rank <= 5
),
MovieKeywords AS (
    SELECT
        fm.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM
        FilteredMovies fm
    LEFT JOIN
        movie_keyword mk ON fm.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        fm.movie_id
),
MoviesWithNulls AS (
    SELECT
        f.movie_id,
        f.title,
        f.production_year,
        f.movie_genre,
        COALESCE(mk.keywords, 'No Keywords') AS keywords
    FROM
        FilteredMovies f
    LEFT JOIN
        MovieKeywords mk ON f.movie_id = mk.movie_id
)
SELECT
    mw.title,
    mw.production_year,
    mw.movie_genre,
    mw.keywords,
    CASE
        WHEN mw.movie_genre = 'Drama' THEN 'Highly Rated'
        WHEN mw.movie_genre = 'Comedy' AND mw.production_year < 2000 THEN 'Classic Comedy'
        ELSE NULL
    END AS category
FROM
    MoviesWithNulls mw
WHERE
    mw.production_year > (
        SELECT AVG(production_year) FROM title
    )
ORDER BY
    mw.production_year DESC, mw.title ASC;
