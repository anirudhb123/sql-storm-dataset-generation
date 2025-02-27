WITH ActorTitles AS (
    SELECT 
        ka.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ka.id ORDER BY at.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ka
    JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS title_count
    FROM 
        ActorTitles
    WHERE 
        recent_movie_rank <= 3
    GROUP BY 
        actor_name
    HAVING 
        COUNT(movie_title) > 5
),
KeywordsPerMovie AS (
    SELECT 
        am.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title am 
    JOIN 
        movie_keyword mk ON am.movie_id = mk.movie_id 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        am.title
)
SELECT 
    ta.actor_name,
    ta.title_count,
    kpm.movie_title,
    kpm.keywords
FROM 
    TopActors ta
LEFT JOIN 
    ActorTitles at ON ta.actor_name = at.actor_name
LEFT JOIN 
    KeywordsPerMovie kpm ON at.movie_title = kpm.movie_title
WHERE 
    kpm.keywords IS NOT NULL
ORDER BY 
    ta.title_count DESC, ta.actor_name;
