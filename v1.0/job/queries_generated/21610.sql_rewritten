WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS title_rank
    FROM 
        aka_title t
    INNER JOIN 
        aka_name a ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
        AND a.name IS NOT NULL
),
ActorInfo AS (
    SELECT 
        c.movie_id,
        c.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order ASC) AS actor_order,
        COALESCE(n.name, 'Unknown') AS actor_name,
        COALESCE(n.gender, 'U') AS actor_gender
    FROM 
        cast_info c
    LEFT JOIN 
        name n ON n.id = c.person_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        AVG(t.title_rank) AS avg_rank
    FROM 
        RankedTitles t
    JOIN 
        complete_cast m ON m.movie_id = t.title_id
    LEFT JOIN 
        ActorInfo c ON c.movie_id = m.movie_id
    GROUP BY 
        m.id
),
ImportantMovies AS (
    SELECT 
        md.movie_id,
        md.total_actors,
        CASE 
            WHEN md.total_actors > 10 THEN 'Blockbuster'
            ELSE 'Indie'
        END AS film_type
    FROM 
        MovieDetails md
    WHERE 
        md.avg_rank IS NOT NULL
)

SELECT 
    im.movie_id,
    t.title,
    im.film_type,
    im.total_actors,
    STRING_AGG(ai.actor_name, ', ') AS actor_names,
    STRING_AGG(CONCAT(ai.actor_name, ' - ', ai.actor_gender), '; ') AS actor_details
FROM 
    ImportantMovies im
JOIN 
    complete_cast cc ON cc.movie_id = im.movie_id
JOIN 
    title t ON t.id = cc.movie_id
LEFT JOIN 
    ActorInfo ai ON ai.movie_id = im.movie_id 
WHERE 
    im.film_type = 'Blockbuster'
GROUP BY 
    im.movie_id, t.title, im.film_type, im.total_actors
ORDER BY 
    im.total_actors DESC, t.title ASC;