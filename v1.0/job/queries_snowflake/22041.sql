
WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        COALESCE(m.season_nr, 0) AS season,
        COALESCE(m.episode_nr, 0) AS episode,
        CAST(m.production_year AS TEXT) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(m.season_nr, 0), COALESCE(m.episode_nr, 0)) AS rn
    FROM
        aka_title m
    WHERE
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.id,
        m.title,
        COALESCE(m.season_nr, 0),
        COALESCE(m.episode_nr, 0),
        CAST(m.production_year AS TEXT),
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY COALESCE(m.season_nr, 0), COALESCE(m.episode_nr, 0)) + 1
    FROM
        aka_title m
    JOIN MovieHierarchy h ON h.movie_id = m.episode_of_id
)
, CastRoles AS (
    SELECT
        c.movie_id,
        r.role,
        COUNT(c.id) AS cast_count,
        LISTAGG(DISTINCT a.name, ', ') AS actors
    FROM
        cast_info c
    JOIN role_type r ON c.role_id = r.id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    WHERE
        c.nr_order IS NOT NULL
    GROUP BY
        c.movie_id,
        r.role
)
, MovieInfo AS (
    SELECT
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(K.keywords, 'None') AS keywords,
        COALESCE(c.cast_count, 0) AS total_cast,
        COALESCE(c.actors, 'No Actors') AS actors_list
    FROM
        MovieHierarchy m
    LEFT JOIN (
        SELECT
            mk.movie_id,
            LISTAGG(k.keyword, ', ') AS keywords
        FROM
            movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
        GROUP BY
            mk.movie_id
    ) K ON K.movie_id = m.movie_id
    LEFT JOIN CastRoles c ON c.movie_id = m.movie_id
)
SELECT
    mi.title AS movie_title,
    mi.production_year AS year,
    COALESCE(mi.keywords, 'No Keywords') AS keywords_list,
    mi.total_cast AS number_of_cast,
    mi.actors_list AS actor_names,
    CASE
        WHEN mi.total_cast > 5 THEN 'Ensemble Cast'
        WHEN mi.total_cast BETWEEN 2 AND 5 THEN 'Small Cast'
        ELSE 'Solo Performance'
    END AS cast_category,
    COUNT(*) FILTER (WHERE mi.actors_list NOT LIKE '%No Actors%') OVER () AS valid_movies_count
FROM
    MovieInfo mi
WHERE
    mi.production_year IS NOT NULL
    AND mi.title ILIKE '%Drama%'
GROUP BY
    mi.title,
    mi.production_year,
    mi.keywords,
    mi.total_cast,
    mi.actors_list
ORDER BY
    mi.production_year DESC,
    mi.title ASC;
