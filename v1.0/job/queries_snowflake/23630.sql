
WITH RECURSIVE ActorWithTitles AS (
    SELECT 
        ak.id AS actor_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
),
FilterMovies AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(*) AS title_count
    FROM 
        ActorWithTitles
    WHERE 
        production_year IS NOT NULL
    GROUP BY 
        movie_title, production_year
    HAVING 
        COUNT(*) > 1
),
DistinctActors AS (
    SELECT 
        DISTINCT actor_id, 
        actor_name 
    FROM 
        ActorWithTitles 
    WHERE 
        title_rank = 1
),
HighRatedTitles AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_present,
        LISTAGG(DISTINCT ci.note, ', ') WITHIN GROUP (ORDER BY ci.note) AS notes_collected
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year >= 2000
    GROUP BY 
        at.title, at.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) > 5
)
SELECT 
    d.actor_name AS "Lead Actor",
    d.actor_id AS "Actor ID",
    f.movie_title AS "Movie Title",
    f.production_year AS "Year of Release",
    COALESCE(ht.cast_count, 0) AS "Total Cast Members",
    COALESCE(ht.notes_present, 0) AS "Notes Present Count",
    ht.notes_collected AS "Collected Notes"
FROM 
    DistinctActors d
LEFT JOIN 
    FilterMovies f ON f.movie_title = (
        SELECT 
            at.movie_title
        FROM 
            ActorWithTitles at 
        WHERE 
            at.actor_id = d.actor_id 
        ORDER BY 
            at.production_year DESC 
        LIMIT 1
    )
LEFT JOIN 
    HighRatedTitles ht ON ht.title = f.movie_title AND ht.production_year = f.production_year
WHERE 
    d.actor_id IS NOT NULL
ORDER BY 
    f.production_year DESC, 
    d.actor_name;
