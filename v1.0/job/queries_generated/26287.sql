WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS aliases,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM
        aka_title ak
    JOIN title t ON ak.movie_id = t.id
    LEFT JOIN cast_info ci ON ci.movie_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),
MovieDetails AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.aliases,
        rm.keywords,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Ensemble Cast'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Small Cast'
            ELSE 'Minimal Cast'
        END AS cast_size
    FROM
        RankedMovies rm
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aliases,
    md.keywords,
    md.cast_size,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    ct.kind AS company_type
FROM
    MovieDetails md
LEFT JOIN movie_companies mc ON mc.movie_id = md.movie_id
LEFT JOIN company_name cn ON mc.company_id = cn.id
LEFT JOIN company_type ct ON mc.company_type_id = ct.id
ORDER BY
    md.production_year DESC,
    md.cast_count DESC;
