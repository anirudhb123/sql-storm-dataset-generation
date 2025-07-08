
WITH ActorTitles AS (
    SELECT 
        a.name AS actor_name,
        t.id AS movie_title,
        t.production_year AS production_year,
        a.md5sum AS actor_md5
    FROM 
        aka_name AS a
    JOIN 
        cast_info AS ci ON a.person_id = ci.person_id
    JOIN 
        aka_title AS t ON ci.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL
        AND t.title LIKE '%Star%'
),

Genres AS (
    SELECT 
        t.id AS title_id,
        k.keyword AS genre
    FROM 
        title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
),

ActorGenreCounts AS (
    SELECT 
        at.actor_name,
        ARRAY_AGG(DISTINCT g.genre) AS genres,
        COUNT(DISTINCT g.genre) AS genre_count
    FROM 
        ActorTitles AS at
    LEFT JOIN 
        Genres AS g ON at.movie_title = g.title_id
    GROUP BY 
        at.actor_name
),

RankedActors AS (
    SELECT 
        actor_name,
        genres,
        genre_count,
        RANK() OVER (ORDER BY genre_count DESC) AS rank
    FROM 
        ActorGenreCounts
)

SELECT 
    actor_name,
    genres,
    genre_count,
    rank
FROM 
    RankedActors
WHERE 
    genre_count >= 3
ORDER BY 
    rank;
