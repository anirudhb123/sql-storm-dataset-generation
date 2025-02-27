WITH ActorMovies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.nr_order < 5
),
TopActors AS (
    SELECT 
        a.id,
        a.name,
        COUNT(DISTINCT am.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        ActorMovies am ON a.person_id = am.person_id
    GROUP BY 
        a.id, a.name
    HAVING 
        COUNT(DISTINCT am.movie_id) > 1
    ORDER BY 
        movie_count DESC
    LIMIT 10
),
ActorKeywords AS (
    SELECT 
        am.person_id,
        mk.keyword,
        COUNT(mk.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        ActorMovies am ON mk.movie_id = am.movie_id
    GROUP BY 
        am.person_id, mk.keyword
    ORDER BY 
        COUNT(mk.keyword) DESC
),
Collaborations AS (
    SELECT 
        a1.person_id AS actor1_id,
        a2.person_id AS actor2_id,
        COUNT(*) AS collaboration_count
    FROM 
        cast_info ci1
    JOIN 
        cast_info ci2 ON ci1.movie_id = ci2.movie_id AND ci1.person_id <> ci2.person_id
    JOIN 
        aka_name a1 ON ci1.person_id = a1.person_id
    JOIN 
        aka_name a2 ON ci2.person_id = a2.person_id
    GROUP BY 
        a1.name, a2.name
    HAVING 
        COUNT(*) > 1
)
SELECT 
    ta.name AS actor_name,
    ta.movie_count AS movies,
    ak.keyword AS popular_keyword,
    SUM(CASE WHEN c.actor1_id IS NOT NULL THEN c.collaboration_count ELSE 0 END) AS total_collaborations
FROM 
    TopActors ta
LEFT JOIN 
    ActorKeywords ak ON ta.id = ak.person_id
LEFT JOIN 
    Collaborations c ON ta.id = c.actor1_id OR ta.id = c.actor2_id
GROUP BY 
    ta.name, ta.movie_count, ak.keyword
HAVING 
    COUNT(DISTINCT ak.keyword) > 2
ORDER BY 
    total_collaborations DESC NULLS LAST, 
    movies DESC, 
    actor_name ASC;

