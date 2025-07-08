
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS actor_rank
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
TopActors AS (
    SELECT 
        ah.person_id
    FROM 
        ActorHierarchy ah
    WHERE 
        ah.actor_rank <= 10
),
ActorMovies AS (
    SELECT 
        a.id AS actor_id,
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword AS movie_keyword,
        t.kind AS movie_kind,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title m ON m.id = c.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        kind_type t ON m.kind_id = t.id
    WHERE 
        a.person_id IN (SELECT person_id FROM TopActors)
),
FilteredMovies AS (
    SELECT 
        am.actor_id,
        am.movie_id,
        am.title,
        am.production_year,
        am.movie_keyword,
        am.movie_kind
    FROM 
        ActorMovies am
    WHERE 
        am.movie_rank <= 5
        AND am.production_year IS NOT NULL
)

SELECT 
    a.name,
    fm.title,
    fm.production_year,
    COUNT(DISTINCT fm.movie_keyword) AS keyword_count,
    LISTAGG(DISTINCT fm.movie_keyword, ', ') AS keywords,
    MAX(fm.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    FilteredMovies fm ON a.id = fm.actor_id
GROUP BY 
    a.name, fm.title, fm.production_year
HAVING 
    COUNT(DISTINCT fm.movie_keyword) > 1
ORDER BY 
    latest_movie_year DESC, a.name;
