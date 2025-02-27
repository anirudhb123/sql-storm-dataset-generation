WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT kc.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info kc ON cc.subject_id = kc.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank_in_year <= 5
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        p.info AS actor_info,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info c ON a.person_id = c.person_id
    INNER JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        a.name, p.info
),
TopActors AS (
    SELECT 
        actor_name,
        actor_info,
        movie_count
    FROM 
        ActorDetails
    WHERE 
        movie_count > 3
    ORDER BY 
        movie_count DESC
)
SELECT 
    pm.title AS 'Popular Movie Title', 
    pm.production_year AS 'Year',
    ta.actor_name AS 'Top Actor', 
    ta.actor_info AS 'Actor Info', 
    ta.movie_count AS 'Number of Movies'
FROM 
    PopularMovies pm
JOIN 
    TopActors ta ON pm.title_id IN (
        SELECT 
            c.movie_id 
        FROM 
            cast_info c
        WHERE 
            c.person_id IN (
                SELECT 
                    a.person_id 
                FROM 
                    aka_name a
                WHERE 
                    a.name = ta.actor_name
            )
    )
ORDER BY 
    pm.production_year DESC, 
    ta.movie_count DESC;
