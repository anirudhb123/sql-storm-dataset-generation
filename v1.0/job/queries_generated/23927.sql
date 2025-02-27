WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(movie_title) AS total_movies,
        AVG(production_year) AS avg_year
    FROM 
        RankedTitles
    GROUP BY 
        actor_name
),
RecentActors AS (
    SELECT 
        actor_name
    FROM 
        RankedTitles
    WHERE 
        title_rank = 1
),
MoviesWithKeywords AS (
    SELECT 
        t.title AS movie_title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)

SELECT 
    a.actor_name,
    a.total_movies,
    a.avg_year,
    COALESCE(m.keywords, 'No keywords') AS movie_keywords
FROM 
    ActorStats a
LEFT JOIN 
    MoviesWithKeywords m ON a.actor_name = (
        SELECT 
            actor_name 
        FROM 
            RankedTitles 
        ORDER BY 
            RANK() OVER (ORDER BY AVG(production_year)) LIMIT 1
    )
WHERE 
    a.actor_name IN (SELECT actor_name FROM RecentActors)
ORDER BY 
    a.total_movies DESC, 
    a.avg_year ASC;

-- Additionally we can implement a bizarre case where we check for NULL titles
SELECT 
    a.actor_name,
    COALESCE(m.title, 'Untitled Movie') AS movie_title_or_default
FROM 
    aka_name a
LEFT OUTER JOIN 
    aka_title m ON a.person_id = (
        SELECT 
            person_id 
        FROM 
            cast_info 
        WHERE 
            movie_id = m.id 
        ORDER BY 
            nr_order 
        LIMIT 1
    )
WHERE 
    a.person_id IS NOT NULL
    OR a.name IS NOT NULL;
