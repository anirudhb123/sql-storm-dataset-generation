WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank
    FROM
        aka_title t
    WHERE
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT
        c.id AS cast_id,
        a.name AS actor_name,
        r.role,
        m.production_year,
        t.title
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN
        role_type r ON c.role_id = r.id
    JOIN
        aka_title m ON c.movie_id = m.id
    JOIN
        RankedMovies rm ON m.id = rm.movie_id
    WHERE
        rm.rank <= 5
),
NullCheck AS (
    SELECT 
        cd.actor_name,
        cd.title,
        COALESCE(cd.production_year, 2023) AS production_year,
        CASE WHEN cd.title IS NULL THEN 'No Title' ELSE 'Has Title' END AS title_status
    FROM
        CastDetails cd
)
SELECT
    n.name AS character_name,
    nc.movie_id,
    COALESCE(mk.keyword, 'No Keyword') AS keywords_associated,
    nc.actor_name,
    nc.production_year,
    nc.title_status
FROM
    char_name n
LEFT JOIN
    movie_keyword mk ON n.imdb_id = mk.keyword_id
LEFT JOIN
    (SELECT DISTINCT c.actor_name, c.title, c.production_year, t.title_status,
                     ROW_NUMBER() OVER (PARTITION BY c.actor_name ORDER BY c.production_year DESC) AS actor_rank
     FROM 
         NullCheck c) nc ON nc.actor_name = n.name
WHERE
    n.imdb_index IS NOT NULL
    AND (nc.title_status = 'Has Title' OR nc.production_year > 2000)
ORDER BY
    nc.production_year DESC, n.name;
