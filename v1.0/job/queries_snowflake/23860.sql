
WITH RECURSIVE
    RankedMovies AS (
        SELECT
            a.id AS movie_id,
            a.title,
            a.production_year,
            ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
        FROM
            aka_title a
    ),
    CastDetails AS (
        SELECT
            c.movie_id,
            COUNT(DISTINCT c.person_id) AS total_cast,
            LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS actor_names,
            MAX(p.gender) AS dominant_gender
        FROM
            cast_info c
        JOIN
            aka_name ak ON c.person_id = ak.person_id
        LEFT JOIN
            name p ON p.id = ak.person_id
        GROUP BY
            c.movie_id
    ),
    MovieGenres AS (
        SELECT
            m.movie_id,
            LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS genres
        FROM
            movie_keyword m
        JOIN
            keyword k ON m.keyword_id = k.id
        GROUP BY
            m.movie_id
    )
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.total_cast,
    cd.actor_names,
    cd.dominant_gender,
    mg.genres,
    CASE
        WHEN cd.dominant_gender = 'M' THEN 'Male Dominated'
        WHEN cd.dominant_gender = 'F' THEN 'Female Dominated'
        ELSE 'Gender Neutral'
    END AS gender_dominance,
    COALESCE((
        SELECT
            COUNT(DISTINCT mc.company_id)
        FROM
            movie_companies mc
        WHERE
            mc.movie_id = rm.movie_id
            AND mc.company_type_id IN (
                SELECT id FROM company_type WHERE kind ILIKE '%Production%'
            )
    ), 0) AS production_company_count
FROM
    RankedMovies rm
LEFT JOIN
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE
    rm.rank <= 5
    AND rm.production_year > 2000
    AND (cd.total_cast > 5 OR mg.genres IS NOT NULL)
ORDER BY
    rm.production_year DESC,
    rm.title;
