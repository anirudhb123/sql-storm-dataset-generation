WITH
    RankedMovies AS (
        SELECT
            t.id AS movie_id,
            t.title,
            t.production_year,
            COUNT(DISTINCT c.person_id) AS cast_count,
            STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
        FROM
            aka_title ak
        JOIN
            title t ON ak.movie_id = t.id
        LEFT JOIN
            cast_info c ON c.movie_id = t.id
        WHERE
            t.production_year BETWEEN 2000 AND 2023
        GROUP BY
            t.id, t.title, t.production_year
    ),
    MovieKeywords AS (
        SELECT
            mk.movie_id,
            STRING_AGG(k.keyword, ', ') AS keywords
        FROM
            movie_keyword mk
        JOIN
            keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    ),
    MovieInfo AS (
        SELECT
            mi.movie_id,
            STRING_AGG(mi.info, '; ') AS additional_info
        FROM
            movie_info mi
        GROUP BY
            mi.movie_id
    )
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.aka_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.additional_info, 'No Additional Info') AS additional_info
FROM
    RankedMovies rm
LEFT JOIN
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN
    MovieInfo mi ON mi.movie_id = rm.movie_id
ORDER BY
    rm.production_year DESC,
    rm.cast_count DESC;
