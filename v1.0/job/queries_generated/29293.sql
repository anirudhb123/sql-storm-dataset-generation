WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND 
        t.title IS NOT NULL
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS movie_count,
        AVG(production_year) AS avg_production_year
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
),
TopActors AS (
    SELECT 
        actor_name,
        movie_count,
        avg_production_year,
        ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        ActorStats
)
SELECT 
    t.actor_name,
    t.movie_count,
    t.avg_production_year,
    k.keyword AS popular_keyword,
    COUNT(mk.keyword_id) AS keyword_count
FROM 
    TopActors t
JOIN 
    movie_keyword mk ON mk.movie_id IN (
        SELECT 
            DISTINCT c.movie_id 
        FROM 
            cast_info c 
        JOIN 
            aka_name a ON a.person_id = c.person_id 
        WHERE 
            a.name = t.actor_name
    )
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.rank <= 10
GROUP BY 
    t.actor_name, 
    t.movie_count, 
    t.avg_production_year, 
    k.keyword
ORDER BY 
    t.movie_count DESC, 
    keyword_count DESC;
