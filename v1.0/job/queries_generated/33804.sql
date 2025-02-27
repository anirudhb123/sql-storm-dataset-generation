WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM
        aka_title mt
    WHERE
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        aka_title m
    JOIN
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
TopMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) as movie_rank
    FROM
        MovieHierarchy mh
),
ActorRoles AS (
    SELECT
        a.person_id,
        c.role_id,
        COUNT(c.movie_id) AS role_count
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    GROUP BY
        a.person_id, c.role_id
),
FeaturedActors AS (
    SELECT
        a.id AS actor_id,
        a.name,
        SUM(ar.role_count) AS total_roles,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
    FROM
        aka_name a
    JOIN
        ActorRoles ar ON a.person_id = ar.person_id
    LEFT JOIN
        movie_keyword mk ON mk.movie_id IN (SELECT mh.movie_id FROM TopMovies mh WHERE mh.movie_rank <= 10)
    LEFT JOIN
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY
        a.id, a.name
)

SELECT
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    fa.name AS Actor_Name,
    fa.total_roles AS Total_Roles,
    fa.keywords AS Associated_Keywords
FROM
    TopMovies tm
JOIN
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN
    FeaturedActors fa ON cc.subject_id = fa.actor_id
WHERE
    fa.total_roles IS NOT NULL
ORDER BY
    Production_Year DESC, Movie_Title;
