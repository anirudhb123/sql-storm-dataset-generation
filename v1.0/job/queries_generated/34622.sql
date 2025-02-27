WITH RECURSIVE ActorHierarchy AS (
    SELECT
        c.person_id,
        a.name AS actor_name,
        1 AS level
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL

    SELECT
        c.person_id,
        a.name AS actor_name,
        h.level + 1
    FROM
        ActorHierarchy h
    JOIN
        cast_info c ON h.person_id = c.person_id
    JOIN
        aka_name a ON c.person_id = a.person_id
    WHERE
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year < 2000)
),
MovieKeywords AS (
    SELECT
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM
        movie_keyword m
    JOIN
        keyword k ON m.keyword_id = k.id
    GROUP BY
        m.movie_id
),
ActorMovieInfo AS (
    SELECT
        a.actor_name,
        ARRAY_AGG(DISTINCT t.title) AS movies,
        ARRAY_AGG(DISTINCT mk.keywords) AS keywords
    FROM
        ActorHierarchy a
    JOIN
        cast_info ci ON a.person_id = ci.person_id
    JOIN
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN
        MovieKeywords mk ON t.id = mk.movie_id
    GROUP BY
        a.actor_name
),
RoleCounts AS (
    SELECT
        ci.role_id,
        rt.role,
        COUNT(*) AS count
    FROM
        cast_info ci
    JOIN
        role_type rt ON ci.role_id = rt.id
    GROUP BY
        ci.role_id, rt.role
)
SELECT
    ami.actor_name,
    ami.movies,
    ami.keywords,
    COALESCE(rc.role, 'Unknown') AS role,
    COALESCE(rc.count, 0) AS role_count,
    RANK() OVER (PARTITION BY ami.actor_name ORDER BY COUNT(DISTINCT ami.movies) DESC) AS movie_rank
FROM
    ActorMovieInfo ami
LEFT JOIN
    RoleCounts rc ON ami.actor_name = (SELECT name FROM aka_name WHERE person_id = (SELECT person_id FROM cast_info WHERE movie_id = (SELECT unnest(ami.movies))))
WHERE
    ami.movies IS NOT NULL
ORDER BY
    movie_rank;
