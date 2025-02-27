WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorRoleCount AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MAX(CASE WHEN r.role = 'Director' THEN 1 ELSE 0 END) AS has_director
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
AkaNames AS (
    SELECT 
        a.person_id,
        STRING_AGG(DISTINCT a.name, ', ') AS aka_names
    FROM 
        aka_name a
    GROUP BY 
        a.person_id
),
MovieInfoWithKeywords AS (
    SELECT 
        m.movie_id,
        COALESCE(m.keywords, 'No keywords') AS keywords,
        COALESCE(c.actor_count, 0) AS actor_count,
        COALESCE(c.has_director, 0) AS has_director
    FROM 
        RankedMovies m
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    LEFT JOIN 
        ActorRoleCount c ON m.movie_id = c.movie_id
)
SELECT 
    m.title,
    m.production_year,
    m.keywords,
    m.actor_count,
    m.has_director,
    COALESCE(a.aka_names, 'Unknown') AS aka_names,
    CASE 
        WHEN m.actor_count > 0 THEN 'Has Stars'
        WHEN m.has_director = 1 THEN 'Only Director'
        ELSE 'Unknown Actors'
    END AS actor_status
FROM 
    MovieInfoWithKeywords m
LEFT JOIN 
    AkaNames a ON m.actor_count > 0 AND a.person_id IN (
        SELECT person_id 
        FROM cast_info 
        WHERE movie_id = m.movie_id
    )
WHERE 
    m.actor_count > 2 OR m.has_director = 1
ORDER BY 
    m.production_year DESC, 
    m.title_rank
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;

