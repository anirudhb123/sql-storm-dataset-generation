WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(r.role) AS leading_role
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MoviesWithInfo AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COALESCE(a.actor_count, 0) AS actor_count,
        a.leading_role,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorRoles a ON m.movie_id = a.movie_id
    LEFT JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.movie_id, m.title, m.production_year, a.actor_count, a.leading_role
),
HighlyRatedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        leading_role,
        keywords,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, actor_count DESC) AS rank
    FROM 
        MoviesWithInfo
    WHERE 
        actor_count > 0
)

SELECT 
    *,
    CASE 
        WHEN actor_count >= 5 THEN 'High Number of Actors'
        WHEN actor_count < 5 AND leading_role IS NOT NULL THEN 'Average Movie'
        ELSE 'Low Actor Count' END AS movie_category,
    (SELECT 
        COUNT(*) 
     FROM 
        complete_cast c 
     WHERE 
        c.movie_id = h.movie_id) AS complete_cast_count,
    COALESCE(NULLIF((SELECT AVG(ci.nr_order) 
                     FROM cast_info ci 
                     WHERE ci.movie_id = h.movie_id), 0), -1) AS average_cast_order
FROM 
    HighlyRatedMovies h
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, actor_count DESC;
