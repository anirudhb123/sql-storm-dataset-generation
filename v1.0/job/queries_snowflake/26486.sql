
WITH RecursiveTitle AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        c.movie_id,
        MIN(c.nr_order) AS first_role_order,
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles_played
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.name, c.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        ai.actor_name,
        ai.first_role_order,
        ai.roles_played,
        ROW_NUMBER() OVER (ORDER BY rt.production_year DESC, rt.title) AS movie_rank
    FROM 
        RecursiveTitle rt
    JOIN 
        ActorInfo ai ON rt.title_id = ai.movie_id
)
SELECT 
    f.title_id,
    f.title,
    f.production_year,
    f.actor_name,
    f.first_role_order,
    f.roles_played
FROM 
    FilteredMovies f
WHERE 
    f.movie_rank <= 10
ORDER BY 
    f.production_year DESC, 
    f.title;
