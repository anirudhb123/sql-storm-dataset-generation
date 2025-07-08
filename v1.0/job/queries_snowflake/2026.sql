
WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS year_rank
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
        AVG(production_year) AS avg_production_year
    FROM 
        RankedTitles
    WHERE 
        year_rank <= 5
    GROUP BY 
        actor_name
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.title
)
SELECT 
    a.actor_name,
    a.total_movies,
    a.avg_production_year,
    COALESCE(m.keywords, 'No keywords') AS keywords
FROM 
    ActorStats a
LEFT JOIN 
    MoviesWithKeywords m ON a.actor_name = m.title
WHERE 
    a.total_movies > 10
ORDER BY 
    a.avg_production_year DESC, 
    a.total_movies DESC;
