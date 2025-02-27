WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(t.title) DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), TopRankedTitles AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        rank <= 5
), ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        c.movie_id,
        r.role AS role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
), SelectedActors AS (
    SELECT 
        actor_id,
        name,
        movie_id,
        role
    FROM 
        ActorInfo
    WHERE 
        role_rank <= 3
), MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        GROUP_CONCAT(a.name || ' (' || a.role || ')') AS actor_list
    FROM 
        TopRankedTitles m
    JOIN 
        SelectedActors a ON m.title_id = a.movie_id
    GROUP BY 
        m.id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actor_list
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC;
