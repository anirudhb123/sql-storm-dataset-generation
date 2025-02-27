WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT cc.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN
        company_type c ON mc.company_type_id = c.id
    WHERE
        t.production_year >= 2000
    GROUP BY
        t.id, t.title, t.production_year
),

GenreCounts AS (
    SELECT
        m.movie_id,
        COUNT(DISTINCT k.keyword) AS genre_count
    FROM
        MovieDetails m
    LEFT JOIN
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.movie_id
)

SELECT
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.aka_names,
    md.keywords,
    gc.genre_count,
    CASE
        WHEN md.cast_count > 10 THEN 'Blockbuster'
        WHEN md.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
        ELSE 'Indie'
    END AS movie_category
FROM
    MovieDetails md
LEFT JOIN
    GenreCounts gc ON md.movie_id = gc.movie_id
ORDER BY
    md.production_year DESC,
    md.cast_count DESC;
