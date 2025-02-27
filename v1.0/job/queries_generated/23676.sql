WITH MovieRoleCounts AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),

HighRoleMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        SUM(mrc.role_count) AS total_roles
    FROM 
        aka_title m
    JOIN 
        MovieRoleCounts mrc ON m.id = mrc.movie_id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.movie_id, m.title
    HAVING 
        SUM(mrc.role_count) > 10
),

CoActorConnections AS (
    SELECT 
        c1.movie_id,
        c1.person_id AS actor1_id,
        c2.person_id AS actor2_id
    FROM 
        cast_info c1
    JOIN 
        cast_info c2 ON c1.movie_id = c2.movie_id AND c1.person_id <> c2.person_id
),

ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        array_agg(DISTINCT c2.actor2_id) AS co_actors
    FROM 
        aka_name a
    LEFT JOIN 
        CoActorConnections c ON a.person_id = c.actor1_id
    GROUP BY 
        a.id, a.name
)

SELECT 
    h.movie_id,
    h.title,
    ad.name AS lead_actor,
    CASE 
        WHEN array_length(ad.co_actors, 1) IS NULL THEN 'No Co-actors'
        ELSE 'Has Co-actors'
    END AS co_actor_status,
    COUNT(DISTINCT h.total_roles) AS total_lead_roles,
    MAX(h.total_roles) AS max_roles
FROM 
    HighRoleMovies h
LEFT JOIN 
    ActorDetails ad ON h.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ad.actor_id)
GROUP BY 
    h.movie_id, h.title, ad.name
ORDER BY 
    max_roles DESC, h.title ASC
LIMIT 10;

-- Additionally, the following section explores movies with keywords but no info types related to them, showcasing null logic:
WITH KeywordedMovies AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
MoviesWithoutInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    WHERE 
        mi.id IS NULL
)
SELECT 
    kwm.movie_id,
    kwm.keyword,
    mw.title AS movie_title,
    COALESCE(mw.title, 'Unknown Title') AS movie_info_status
FROM 
    KeywordedMovies kwm
LEFT JOIN 
    MoviesWithoutInfo mw ON kwm.movie_id = mw.movie_id
ORDER BY 
    kwm.keyword;
