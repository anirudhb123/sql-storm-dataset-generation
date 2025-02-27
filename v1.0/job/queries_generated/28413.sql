WITH RankedMovies AS (
    SELECT
        at.id AS movie_id,
        at.title,
        at.production_year,
        ak.name AS actor_name,
        ak.id AS actor_id,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS rank
    FROM
        aka_title AT
    JOIN
        cast_info CI ON AT.id = CI.movie_id
    JOIN
        aka_name AK ON CI.person_id = AK.person_id
    WHERE
        AT.production_year >= 2000 AND
        AT.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorStats AS (
    SELECT
        rm.movie_id,
        rm.title,
        COUNT(rm.actor_id) AS actor_count,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actor_names
    FROM
        RankedMovies rm
    GROUP BY
        rm.movie_id, rm.title
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ms.movie_id,
    ms.title,
    ms.actor_count,
    ms.actor_names,
    mk.keywords
FROM 
    ActorStats ms
LEFT JOIN 
    MovieKeywords mk ON ms.movie_id = mk.movie_id
ORDER BY 
    ms.actor_count DESC,
    ms.title;
