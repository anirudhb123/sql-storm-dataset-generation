WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(m.production_year, 0) AS production_year,
        ROW_NUMBER() OVER (PARTITION BY COALESCE(m.production_year, 0) ORDER BY m.production_year DESC, m.title) AS year_rank
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature')) 
        AND m.production_year IS NOT NULL
),
MaxRankedMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        year_rank = 1
),
MovieWithKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        MaxRankedMovies m
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = m.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        m.title
),
ActorRoles AS (
    SELECT 
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        role_type r ON r.id = ci.role_id
    GROUP BY 
        a.name, r.role
),
RoleCounts AS (
    SELECT 
        actor_name,
        role_name,
        movie_count,
        RANK() OVER (PARTITION BY role_name ORDER BY movie_count DESC) AS role_rank
    FROM 
        ActorRoles
    WHERE 
        movie_count > 5  -- filter for actors with more than 5 roles
),
MoviesWithTopActors AS (
    SELECT 
        m.title,
        a.actor_name,
        ROW_NUMBER() OVER (PARTITION BY m.title ORDER BY ra.role_rank) AS actor_rank
    FROM 
        MaxRankedMovies m
    JOIN 
        RoleCounts ra ON m.movie_id IN (SELECT movie_id FROM cast_info ci JOIN aka_name an ON an.person_id = ci.person_id WHERE an.name = ra.actor_name)
)
SELECT 
    mw.title,
    mw.actor_name,
    mw.actor_rank,
    COALESCE(mw.keywords, 'No keywords') AS keywords,
    CASE 
        WHEN mw.actor_rank IS NULL THEN 'Actor Unranked'
        ELSE 'Actor Ranked'
    END AS actor_status
FROM 
    MoviesWithTopActors mw
LEFT JOIN 
    MovieWithKeywords mk ON mw.title = mk.title
WHERE 
    mw.actor_rank <= 3  -- Top 3 actors per movie
ORDER BY 
    mw.title, mw.actor_rank;

-- Additionally, to include an obscure example of NULL logic
SELECT 
    m.title,
    COUNT(c.id) AS total_cast,
    ROUND(AVG(CASE WHEN c.person_role_id IS NULL THEN NULL ELSE 1 END), 2) AS non_null_role_avg
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON c.movie_id = m.id
GROUP BY 
    m.title
HAVING 
    COUNT(c.id) > 10 AND ROUND(AVG(CASE WHEN c.person_role_id IS NULL THEN NULL ELSE 1 END), 2) IS NOT NULL;
