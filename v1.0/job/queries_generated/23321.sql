WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        RANK() OVER (PARTITION BY k.keyword ORDER BY t.production_year DESC) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovies AS (
    SELECT 
        a.name AS actor_name,
        RM.movie_title,
        RM.production_year,
        COUNT(CAST(c.role_id AS INTEGER)) AS role_count,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS note_exists
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        RankedMovies RM ON c.movie_id = RM.movie_title
    GROUP BY 
        a.name, RM.movie_title, RM.production_year
),
NullChecks AS (
    SELECT 
        t.title,
        COALESCE(ci.note, 'No note provided') AS note_provided,
        CASE
            WHEN ci.note IS NULL THEN 'No note'
            ELSE 'Note exists'
        END AS note_status,
        (SELECT COUNT(*)
         FROM movie_info mi 
         WHERE mi.movie_id = t.id AND mi.info_type_id IS NULL) AS null_info_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
)
SELECT 
    AM.actor_name,
    AM.movie_title,
    AM.production_year,
    AM.role_count,
    NC.note_provided,
    NC.note_status,
    NC.null_info_count
FROM 
    ActorMovies AM
JOIN 
    NullChecks NC ON AM.movie_title = NC.title
WHERE 
    AM.role_count > 0
    AND NC.null_info_count = 0
    AND AM.keyword_rank = 1
ORDER BY 
    AM.production_year DESC, 
    AM.actor_name ASC;

WITH RECURSIVE MapLinks AS (
    SELECT movie_id, linked_movie_id, 1 AS depth
    FROM movie_link
    WHERE movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)

    UNION ALL

    SELECT ml.movie_id, ml.linked_movie_id, depth + 1
    FROM movie_link ml
    JOIN MapLinks ml2 ON ml.movie_id = ml2.linked_movie_id
    WHERE ml2.depth < 5
)
SELECT 
    ml.movie_id,
    COUNT(ml.linked_movie_id) AS total_linked_movies,
    MAX(ml.depth) AS max_depth
FROM 
    MapLinks ml
GROUP BY 
    ml.movie_id
HAVING 
    COUNT(ml.linked_movie_id) > 3
ORDER BY 
    total_linked_movies DESC;
