
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
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    MoviesWithKeywords m ON m.movie_title = (
        SELECT 
            rr.movie_title 
        FROM 
            RankedTitles rr 
        ORDER BY 
            rr.title_rank 
        LIMIT 1
    )
WHERE 
    a.actor_name IN (SELECT actor_name FROM RecentActors)
ORDER BY 
    a.total_movies DESC, 
    a.avg_year ASC;
