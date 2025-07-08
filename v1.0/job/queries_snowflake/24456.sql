
WITH RecursiveMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        tk.keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY tk.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword tk ON mk.keyword_id = tk.id
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleDistribution AS (
    SELECT 
        c.person_id,
        r.role AS actor_role,
        COUNT(c.id) AS movie_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id, r.role
),
TopActors AS (
    SELECT 
        ard.person_id,
        ard.actor_role,
        ard.movie_count,
        RANK() OVER (PARTITION BY ard.actor_role ORDER BY ard.movie_count DESC) AS role_rank
    FROM 
        ActorRoleDistribution ard
)
SELECT 
    ka.name AS actor_name,
    tm.movie_id,
    tm.title,
    tm.production_year,
    LISTAGG(DISTINCT tm.keyword, ', ') WITHIN GROUP (ORDER BY tm.keyword) AS keywords
FROM 
    aka_name ka
JOIN 
    cast_info ci ON ka.person_id = ci.person_id
JOIN 
    RecursiveMovieInfo tm ON ci.movie_id = tm.movie_id
JOIN 
    TopActors ta ON ta.person_id = ka.person_id AND ta.role_rank <= 3
WHERE 
    tm.production_year >= 2000
    AND (tm.keyword IS NOT NULL OR (tm.keyword IS NULL AND ka.name IS NOT NULL))
GROUP BY 
    ka.name, tm.movie_id, tm.title, tm.production_year
ORDER BY 
    ka.name, tm.production_year DESC, tm.title;
