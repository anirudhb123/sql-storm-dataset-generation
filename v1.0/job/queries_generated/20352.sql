WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rn
    FROM 
        aka_title t
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role) ORDER BY a.name) AS actor_role_summary
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    LEFT JOIN 
        role_type r ON r.id = c.role_id
    GROUP BY 
        c.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
CombinedData AS (
    SELECT 
        m.title,
        m.production_year,
        ar.num_actors,
        ar.actor_role_summary,
        mk.keywords
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorRoles ar ON ar.movie_id = (SELECT movie_id FROM complete_cast cc WHERE cc.id = m.id LIMIT 1)
    LEFT JOIN 
        MovieKeywords mk ON mk.movie_id = (SELECT movie_id FROM complete_cast cc WHERE cc.id = m.id LIMIT 1)
    WHERE 
        m.production_year IS NOT NULL 
        AND m.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie' OR kind = 'film')
        AND ar.num_actors > 2
),
FinalOutput AS (
    SELECT 
        cd.title,
        cd.production_year,
        COALESCE(cd.num_actors, 0) AS num_actors,
        CD.actor_role_summary,
        CASE 
            WHEN cd.keywords IS NOT NULL THEN cd.keywords 
            ELSE 'No keywords found' 
        END AS keywords
    FROM 
        CombinedData cd
)
SELECT 
    *,
    CASE 
        WHEN production_year > 2000 THEN 'Modern Era' 
        WHEN production_year BETWEEN 1980 AND 2000 THEN 'Late 20th Century'
        ELSE 'Classic'
    END AS era,
    NULLIF(num_actors, 0) AS actor_count
FROM 
    FinalOutput
ORDER BY 
    production_year DESC, title;
