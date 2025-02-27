WITH RECURSIVE MovieHierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM
        aka_title m
    WHERE
        m.episode_of_id IS NULL
    UNION ALL
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1 AS level,
        mh.movie_id AS parent_id
    FROM
        aka_title m
    JOIN
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
),
ActorInfo AS (
    SELECT
        c.person_id,
        a.name,
        r.role,
        COUNT(ci.movie_id) AS total_movies
    FROM
        cast_info ci
    JOIN
        aka_name a ON ci.person_id = a.person_id
    JOIN
        role_type r ON ci.role_id = r.id
    GROUP BY
        c.person_id, a.name, r.role
),
TopActors AS (
    SELECT
        person_id,
        name,
        role,
        total_movies,
        RANK() OVER (ORDER BY total_movies DESC) AS rank
    FROM
        ActorInfo
    WHERE
        total_movies > 5
),
MovieInfoExtended AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mi.info, 'No info available') AS info,
        COALESCE(ca.name, 'Unknown actor') AS lead_actor,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS rn
    FROM
        MovieHierarchy mh
    LEFT JOIN
        complete_cast cc ON mh.movie_id = cc.movie_id
    LEFT JOIN
        aka_name ca ON cc.subject_id = ca.person_id
    LEFT JOIN
        movie_info mi ON mh.movie_id = mi.movie_id
    WHERE
        mh.level < 3 -- Limits to only top-level episodes and their direct children
)
SELECT
    me.title,
    me.production_year,
    me.info,
    COALESCE(ta.name, 'No lead actor') AS top_actor,
    ta.total_movies AS actor_movie_count
FROM
    MovieInfoExtended me
LEFT JOIN
    TopActors ta ON me.lead_actor = ta.name
WHERE
    me.rn = 1 -- Get only the first lead actor for simplicity
ORDER BY
    me.production_year DESC, actor_movie_count DESC NULLS LAST
LIMIT 50;

This SQL query combines several advanced constructs, including:

1. **Recursive CTEs** to generate a hierarchy of movies.
2. **Window functions** to rank and partition actor info based on their total movies.
3. **Outer joins** to include movies without related actor or info records.
4. **Complicated predicates** and **NULL logic** to handle missing data gracefully.
5. A filtering and ordering strategy to select only the most relevant data for the output. 

It retrieves a list of movies, their production years, info, the top actor associated with each (if available), and the number of movies that actor has participated in, carefully handling scenarios where data might be incomplete.
