WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS ranking
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
),

TopActors AS (
    SELECT 
        actor_name,
        COUNT(*) AS movie_count
    FROM 
        RankedTitles
    WHERE 
        ranking <= 5
    GROUP BY 
        actor_name
    ORDER BY 
        movie_count DESC
    LIMIT 10
),

ActorDetails AS (
    SELECT 
        ta.actor_name,
        p.info AS actor_info
    FROM 
        TopActors ta
    JOIN 
        person_info p ON ta.actor_name = (SELECT name FROM aka_name WHERE person_id = p.person_id LIMIT 1)
),

MovieKeywords AS (
    SELECT 
        t.title AS movie_title,
        k.keyword AS keyword
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
)

SELECT 
    ad.actor_name,
    ad.actor_info,
    COUNT(mk.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    ARRAY_AGG(DISTINCT mt.movie_title) AS top_movies
FROM 
    ActorDetails ad
JOIN 
    MovieKeywords mk ON ad.actor_name IN (SELECT a.name FROM aka_name a WHERE a.person_id = (SELECT person_id FROM person_info pi WHERE pi.info = ad.actor_info LIMIT 1))
JOIN 
    RankedTitles mt ON ad.actor_name = mt.actor_name
GROUP BY 
    ad.actor_name, ad.actor_info
ORDER BY 
    keyword_count DESC;
