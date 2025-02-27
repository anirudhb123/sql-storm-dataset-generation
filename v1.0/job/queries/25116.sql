WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        r.role AS actor_role,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
    AND 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorCounts AS (
    SELECT
        movie_id,
        COUNT(actor_name) AS actor_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_id
),
TitleKeyword AS (
    SELECT 
        m.id AS movie_id,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE
        m.production_year >= 2000
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ac.actor_count,
    tk.keywords,
    STRING_AGG(rm.actor_name, ', ' ORDER BY rm.actor_rank) AS actor_names
FROM 
    RankedMovies rm
JOIN 
    ActorCounts ac ON rm.movie_id = ac.movie_id
JOIN 
    TitleKeyword tk ON rm.movie_id = tk.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ac.actor_count, tk.keywords
ORDER BY 
    rm.production_year DESC, ac.actor_count DESC;
