WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title m ON ml.linked_movie_id = m.id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        cin.name AS actor_name,
        rt.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM
        cast_info ci
    JOIN
        aka_name cin ON ci.person_id = cin.person_id
    JOIN
        role_type rt ON ci.role_id = rt.id
),
MovieDetails AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        array_agg(DISTINCT ar.actor_name ORDER BY ar.actor_rank) AS actors,
        string_agg(DISTINCT k.keyword, ', ') AS keywords
    FROM
        MovieHierarchy mh
    LEFT JOIN
        ActorRoles ar ON mh.movie_id = ar.movie_id
    LEFT JOIN
        movie_keyword mk ON mh.movie_id = mk.movie_id
    LEFT JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mh.movie_id, mh.title, mh.production_year
)
SELECT
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(md.actors, '{}') AS actors,
    COALESCE(md.keywords, 'N/A') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies
FROM
    MovieDetails md
LEFT JOIN
    movie_companies mc ON md.movie_id = mc.movie_id
GROUP BY
    md.movie_id, md.title, md.production_year
ORDER BY
    md.production_year DESC
LIMIT 10;

-- This query performs the following:
-- 1. Generates a recursive CTE to build a hierarchy of movies, including linked movies.
-- 2. Creates a comprehensive list of actors and their roles using ROW_NUMBER().
-- 3. Joins in keywords to enhance data about movies.
-- 4. Counts the distinct number of companies involved in the production of each movie.
-- 5. Selects the top 10 most recent movies with full details.
