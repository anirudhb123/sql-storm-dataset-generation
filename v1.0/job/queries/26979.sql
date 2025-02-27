
WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        STRING_AGG(DISTINCT ak.name, ',') AS aka_names,
        STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
        STRING_AGG(DISTINCT c.name, ',') AS company_names,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM
        aka_title t
    LEFT JOIN aka_name ak ON ak.person_id = t.id
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN movie_companies mc ON mc.movie_id = t.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN cast_info ca ON ca.movie_id = t.id
    GROUP BY
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT
        md.movie_id,
        md.title,
        md.production_year,
        md.kind_id,
        md.aka_names,
        md.keywords,
        md.company_names,
        md.cast_count
    FROM
        MovieDetails md
    WHERE
        md.production_year >= 2000 AND
        md.cast_count > 5
)
SELECT
    fm.movie_id,
    fm.title,
    fm.production_year,
    k.kind AS movie_kind,
    fm.aka_names,
    fm.keywords,
    fm.company_names,
    fm.cast_count
FROM
    FilteredMovies fm
JOIN kind_type k ON k.id = fm.kind_id
ORDER BY
    fm.production_year DESC,
    fm.title;
