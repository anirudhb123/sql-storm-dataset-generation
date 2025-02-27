WITH RecursiveActorRoles AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        t.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY t.production_year DESC) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL -- Ensuring we don't consider movies without a year
),
RecentRoles AS (
    SELECT 
        person_id, 
        actor_name, 
        movie_title
    FROM 
        RecursiveActorRoles
    WHERE 
        role_rank <= 3 -- Getting the 3 most recent roles per actor
),
ActorGenreStats AS (
    SELECT 
        a.person_id,
        COUNT(DISTINCT t.kind_id) AS genre_count,
        STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.person_id
),
FinalStats AS (
    SELECT 
        r.actor_name,
        r.movie_title,
        COALESCE(gs.genre_count, 0) AS genre_count,
        COALESCE(gs.keywords, 'No Keywords') AS keywords
    FROM 
        RecentRoles r
    LEFT JOIN 
        ActorGenreStats gs ON r.person_id = gs.person_id
)
SELECT 
    f.actor_name,
    f.movie_title,
    f.genre_count,
    f.keywords,
    CASE 
        WHEN f.genre_count > 5 THEN 'Diverse Actor'
        WHEN f.genre_count > 0 THEN 'Niche Actor'
        ELSE 'Unknown Genre Affiliation'
    END AS actor_category,
    CASE 
        WHEN f.keywords ILIKE '%action%' THEN 'Action Lover'
        WHEN f.keywords ILIKE '%drama%' THEN 'Drama Enthusiast'
        ELSE 'Genre Agnostic'
    END AS genre_preference,
    (SELECT COUNT(*) 
        FROM movie_info m 
        WHERE m.info ILIKE '%award%' AND m.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = r.person_id)
    ) AS awards_count
FROM 
    FinalStats f
ORDER BY 
    f.actor_name ASC,
    f.genre_count DESC;
