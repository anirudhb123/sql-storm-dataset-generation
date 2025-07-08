
WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ak.name AS aka_name,
        k.keyword AS movie_keyword
    FROM
        title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    LEFT JOIN
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN
        name a ON ak.person_id = a.imdb_id
    LEFT JOIN
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
),
MovieInfo AS (
    SELECT
        md.movie_id,
        md.movie_title,
        md.production_year,
        LISTAGG(DISTINCT md.actor_name, ', ') WITHIN GROUP (ORDER BY md.actor_name) AS actor_names,
        LISTAGG(DISTINCT md.aka_name, ', ') WITHIN GROUP (ORDER BY md.aka_name) AS aka_names,
        LISTAGG(DISTINCT md.movie_keyword, ', ') WITHIN GROUP (ORDER BY md.movie_keyword) AS keywords
    FROM
        MovieDetails md
    GROUP BY
        md.movie_id, md.movie_title, md.production_year
)
SELECT
    mi.movie_id,
    mi.movie_title,
    mi.production_year,
    mi.actor_names,
    mi.aka_names,
    COALESCE(NULLIF(mi.keywords, ''), 'No Keywords') AS keywords
FROM
    MovieInfo mi
WHERE
    mi.production_year > 2000
ORDER BY
    mi.production_year DESC, mi.movie_title ASC;
