WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS title_rank
    FROM
        aka_title t
    WHERE
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'movie%')
),
ActorsCount AS (
    SELECT
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM
        cast_info c
    GROUP BY
        c.movie_id
),
NullCheck AS (
    SELECT
        m.movie_id,
        COALESCE(a.actor_count, 0) AS actor_count,
        CASE 
            WHEN a.actor_count IS NULL THEN 'No Actors'
            WHEN a.actor_count > 10 THEN 'Blockbuster'
            ELSE 'Indie'
        END AS movie_type
    FROM
        RankedMovies m
    LEFT JOIN
        ActorsCount a ON m.movie_id = a.movie_id
)
SELECT
    m.movie_id,
    m.title,
    m.production_year,
    n.language,
    CASE 
        WHEN m.production_year < 1980 THEN 'Classic'
        WHEN m.production_year BETWEEN 1980 AND 2000 THEN 'Modern'
        ELSE 'Contemporary'
    END AS era,
    nc.actor_count,
    nc.movie_type,
    (SELECT AVG(rating) FROM movie_info mi WHERE mi.movie_id = m.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'rating')) AS avg_rating,
    CASE
        WHEN md5sum IS NOT NULL AND md5sum = (SELECT md5sum FROM aka_name WHERE person_id = (SELECT MIN(person_id) FROM cast_info WHERE movie_id = m.movie_id LIMIT 1))
        THEN 1
        ELSE 0
    END AS obscure_semantics_flag 
FROM
    RankedMovies m
LEFT JOIN NULLCheck nc ON m.movie_id = nc.movie_id
LEFT JOIN movie_info mi ON m.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
LEFT JOIN (
    SELECT
        DISTINCT movie_id,
        STRING_AGG(DISTINCT company_id::text, ', ') AS company_ids,
        STRING_AGG(DISTINCT company_type_id::text, ', ') AS company_types
    FROM
        movie_companies
    GROUP BY
        movie_id
) AS companies ON m.movie_id = companies.movie_id
LEFT JOIN (
    SELECT
        movie_id,
        MAX(IMDB_ID) AS highest_imdb
    FROM
        aka_title
    GROUP BY
        movie_id
) AS titles ON m.movie_id = titles.movie_id
WHERE
    m.title_rank <= 5 AND nc.actor_count IS NOT NULL
ORDER BY
    m.production_year DESC, m.title
FETCH FIRST 50 ROWS ONLY;
