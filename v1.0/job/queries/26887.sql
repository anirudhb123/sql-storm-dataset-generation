WITH RankedActors AS (
    SELECT
        a.id AS actor_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM
        aka_name a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY
        a.id, a.name
    HAVING
        COUNT(ci.movie_id) > 5
), MoviesWithKeywords AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        aka_title m
    JOIN
        movie_keyword mk ON m.id = mk.movie_id
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        m.id, m.title
), ActorMovieInfo AS (
    SELECT
        ra.actor_id,
        ra.actor_name,
        mwk.movie_id,
        mwk.movie_title,
        mwk.keywords,
        COALESCE(mi.info, 'No additional info') AS info
    FROM
        RankedActors ra
    JOIN
        cast_info ci ON ra.actor_id = ci.person_id
    JOIN
        MoviesWithKeywords mwk ON ci.movie_id = mwk.movie_id
    LEFT JOIN
        movie_info mi ON mwk.movie_id = mi.movie_id AND mi.info_type_id = 1 
)

SELECT
    ami.actor_name,
    COUNT(DISTINCT ami.movie_id) AS movies_participated,
    STRING_AGG(DISTINCT ami.movie_title, '; ') AS movie_titles,
    STRING_AGG(DISTINCT ami.keywords, '; ') AS all_keywords,
    MIN(ami.info) AS additional_info 
FROM
    ActorMovieInfo ami
GROUP BY
    ami.actor_name
ORDER BY
    movies_participated DESC
LIMIT 10;