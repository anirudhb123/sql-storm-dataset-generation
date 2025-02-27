WITH RecursivePersonRoles AS (
    SELECT 
        ci.person_id,
        rt.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id, rt.role
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY cp.role_count DESC) AS actor_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        RecursivePersonRoles cp ON ci.person_id = cp.person_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    WHERE 
        t.publication_year IS NOT NULL
),
MovieStats AS (
    SELECT 
        rm.title,
        rm.production_year,
        COUNT(*) AS actor_count,
        STRING_AGG(DISTINCT rm.actor_name, ', ') AS actor_names,
        AVG(rm.actor_rank) AS average_rank
    FROM 
        RankedMovies rm
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    ms.title,
    ms.production_year,
    ms.actor_count,
    ms.actor_names,
    ms.average_rank,
    CASE 
        WHEN ms.actor_count > 10 THEN 'Ensemble Cast'
        WHEN ms.average_rank < 5 THEN 'Star Power'
        ELSE 'Small Cast'
    END AS cast_type,
    COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
    CASE 
        WHEN EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = ms.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis'))
        THEN 'Has Synopsis'
        ELSE 'No Synopsis'
    END AS synopsis_status
FROM 
    MovieStats ms
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ms.movie_id
LEFT JOIN 
    title ti ON ti.title = ms.title AND ti.production_year = ms.production_year
WHERE 
    (UPPER(ms.title) LIKE '%ACTION%' OR ms.production_year BETWEEN 2000 AND 2023)
ORDER BY 
    ms.actor_count DESC,
    ms.average_rank ASC
LIMIT 50;
