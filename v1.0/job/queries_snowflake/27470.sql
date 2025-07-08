
WITH RankedTitles AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year >= 2000
),
TopActors AS (
    SELECT 
        movie_title,
        production_year,
        LISTAGG(actor_name, ', ') WITHIN GROUP (ORDER BY actor_name) AS actor_names
    FROM 
        RankedTitles
    WHERE 
        actor_rank <= 3
    GROUP BY 
        movie_title, production_year
)
SELECT 
    tt.movie_title,
    tt.production_year,
    COALESCE(NULLIF(tt.actor_names, ''), 'No Actors Listed') AS top_actors
FROM 
    TopActors tt
ORDER BY 
    tt.production_year DESC, 
    tt.movie_title;
