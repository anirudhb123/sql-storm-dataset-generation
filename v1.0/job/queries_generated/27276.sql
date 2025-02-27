WITH MovieKeywords AS (
    SELECT
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
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
        STRING_AGG(DISTINCT mi.info, '; ') AS information
    FROM
        movie_info mi
    GROUP BY
        mi.movie_id
),
CompleteCast AS (
    SELECT
        cc.movie_id,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_list
    FROM
        complete_cast cc
    JOIN
        person_info pi ON cc.subject_id = pi.person_id
    JOIN
        name p ON pi.person_id = p.imdb_id
    GROUP BY
        cc.movie_id
)

SELECT
    t.title,
    t.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.information, 'No Additional Info') AS additional_info,
    COALESCE(cc.cast_list, 'No Cast Info') AS cast_list
FROM
    title t
LEFT JOIN
    MovieKeywords mk ON t.id = mk.movie_id
LEFT JOIN
    MovieInfo mi ON t.id = mi.movie_id
LEFT JOIN
    CompleteCast cc ON t.id = cc.movie_id
WHERE
    t.production_year >= 2000
ORDER BY
    t.production_year DESC,
    t.title ASC
LIMIT 50;
