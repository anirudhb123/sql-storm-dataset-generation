WITH Recursive_Movie_Chain AS (
    SELECT
        m_id,
        title,
        production_year,
        linked_movie_id,
        1 AS depth
    FROM
        movie_link ml
    JOIN
        title t ON ml.movie_id = t.id
    WHERE
        ml.link_type_id = (SELECT id FROM link_type WHERE link = 'See Also')
    
    UNION ALL
    
    SELECT
        ml.m_id,
        t.title,
        t.production_year,
        ml.linked_movie_id,
        rmc.depth + 1
    FROM
        movie_link ml
    JOIN
        Recursive_Movie_Chain rmc ON ml.movie_id = rmc.linked_movie_id
    JOIN
        title t ON ml.linked_movie_id = t.id
)
, Actor_Roles AS (
    SELECT 
        ci.movie_id,
        count(DISTINCT ci.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS roles_with_notes
    FROM
        cast_info ci
    JOIN
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY
        ci.movie_id
)
, Movie_Stats AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ar.actor_count, 0) AS actor_count,
        COALESCE(ar.actors, 'No Actors') AS actors,
        COALESCE(ar.roles_with_notes, 0) AS roles_with_notes,
        rmc.depth AS link_chain_depth
    FROM
        title t
    LEFT JOIN
        Actor_Roles ar ON t.id = ar.movie_id
    LEFT JOIN
        Recursive_Movie_Chain rmc ON t.id = rmc.m_id
)
SELECT
    ms.movie_id,
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.actors,
    ms.roles_with_notes,
    CASE 
        WHEN ms.actor_count > 0 THEN 'Has Actors'
        WHEN ms.actor_count = 0 AND rmc.depth IS NULL THEN 'No Actors, No Links'
        ELSE 'Link Exists without Actors'
    END AS status
FROM
    Movie_Stats ms
LEFT JOIN
    Recursive_Movie_Chain rmc ON ms.movie_id = rmc.m_id
WHERE
    ms.production_year >= 2000 AND (ms.actor_count > 5 OR ms.link_chain_depth IS NOT NULL)
ORDER BY 
    ms.production_year DESC,
    ms.actor_count DESC,
    COALESCE(NULLIF(ms.actors, 'No Actors'), 'ZZZZZ');
