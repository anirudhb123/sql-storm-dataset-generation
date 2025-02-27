WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(DISTINCT m.company_id) AS company_count
    FROM 
        aka_title t
    JOIN 
        movie_companies m ON m.movie_id = t.movie_id
    GROUP BY t.id, t.title, t.production_year
),
DistinctActors AS (
    SELECT 
        a.person_id,
        a.name,
        ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY a.person_id) AS name_rank
    FROM 
        aka_name a
    WHERE 
        a.name IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        c.role_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY c.movie_id, c.role_id
),
MoviesWithoutActors AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(ac.actor_count, 0) AS actor_count
    FROM 
        aka_title t
    LEFT JOIN 
        ActorRoles ac ON ac.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL AND
        t.title IS NOT NULL AND 
        NOT EXISTS (
            SELECT 1 
            FROM cast_info ci 
            WHERE ci.movie_id = t.movie_id
        )
),
FinalSelection AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.title_rank,
        mw.actor_count,
        dt.name
    FROM 
        RankedTitles rt
    LEFT JOIN 
        MoviesWithoutActors mw ON mw.movie_id = rt.title_id 
    LEFT JOIN 
        DistinctActors dt ON dt.name_rank = 1
    WHERE 
        rt.company_count > 3 AND 
        rt.title_rank <= 5 AND 
        mw.actor_count > 0
)
SELECT 
    fs.title,
    fs.production_year,
    fs.actor_count,
    CASE 
        WHEN fs.actor_count > 10 THEN 'Overwhelming Cast'
        WHEN fs.actor_count BETWEEN 5 AND 10 THEN 'Decent Cast'
        ELSE 'Minimal Cast'
    END AS cast_description,
    LOWER(fs.name) AS lead_actor_lowercase
FROM 
    FinalSelection fs
WHERE 
    fs.production_year >= 2000 
ORDER BY 
    fs.production_year DESC, 
    fs.title;
