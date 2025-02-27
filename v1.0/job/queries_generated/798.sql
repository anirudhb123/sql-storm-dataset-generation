WITH RecursiveActorMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        c.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        a.name IS NOT NULL
        AND t.production_year IS NOT NULL
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        COUNT(movie_id) AS movie_count
    FROM 
        RecursiveActorMovies
    GROUP BY 
        actor_id, actor_name
    HAVING 
        COUNT(movie_id) > 5
),
ActorsMoviesWithKeywords AS (
    SELECT 
        tam.actor_id,
        tam.actor_name,
        tam.movie_id,
        tam.title,
        tam.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        TopActors tam
    JOIN 
        movie_keyword mk ON tam.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tam.actor_id, tam.actor_name, tam.movie_id, tam.title, tam.production_year
)
SELECT 
    amw.actor_name,
    amw.title,
    amw.production_year,
    COALESCE(amw.keywords, 'No Keywords') AS movie_keywords,
    CASE 
        WHEN amw.production_year < 2000 
        THEN 'Classic' 
        ELSE 'Modern' 
    END AS era
FROM 
    ActorsMoviesWithKeywords amw
WHERE 
    amw.production_year >= 1990
ORDER BY 
    amw.production_year DESC, 
    amw.actor_name;
