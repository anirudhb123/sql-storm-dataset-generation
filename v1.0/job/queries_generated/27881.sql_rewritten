WITH RankedTitles AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        r.role,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY ak.name) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000 
),
TopActors AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(actor_name, ', ') AS actors_list
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
    tt.actors_list,
    COUNT(DISTINCT ci.person_id) AS total_actors,
    COUNT(mk.id) AS keyword_count
FROM 
    TopActors tt
JOIN 
    title t ON tt.movie_title = t.title AND tt.production_year = t.production_year
LEFT JOIN 
    cast_info ci ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
GROUP BY 
    tt.movie_title, tt.production_year, tt.actors_list
ORDER BY 
    tt.production_year DESC, tt.movie_title;