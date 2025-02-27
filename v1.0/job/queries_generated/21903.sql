WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.person_id,
        r.role, 
        COUNT(*) AS role_count,
        SUM(CASE WHEN m.production_year IS NULL THEN 0 ELSE 1 END) AS valid_movie_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.id 
    GROUP BY 
        c.person_id, r.role
),
DistinctGenres AS (
    SELECT DISTINCT 
        kt.id AS keyword_id,
        kt.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
)
SELECT 
    a.name AS actor_name,
    t.title AS title,
    t.production_year,
    ar.role AS character_role,
    ar.role_count,
    ar.valid_movie_count,
    dg.keyword AS genre_key,
    CASE 
        WHEN ar.role_count > 10 THEN 'Prolific Actor'
        WHEN ar.valid_movie_count = 0 THEN 'No Valid Movies'
        ELSE 'Active Actor'
    END AS actor_status
FROM 
    aka_name a
JOIN 
    ActorRoles ar ON a.person_id = ar.person_id
JOIN 
    RankedTitles t ON ar.valid_movie_count > 0 AND t.title_id IN (
        SELECT movie_id 
        FROM cast_info 
        WHERE person_id = a.person_id
    )
LEFT JOIN 
    movie_keyword mk ON t.title_id = mk.movie_id
LEFT JOIN 
    DistinctGenres dg ON mk.keyword_id = dg.keyword_id
WHERE 
    a.name IS NOT NULL 
    AND a.id NOT IN (SELECT person_id FROM person_info WHERE info_type_id IS NULL)
ORDER BY 
    actor_name, 
    title_rank, 
    t.production_year DESC;
