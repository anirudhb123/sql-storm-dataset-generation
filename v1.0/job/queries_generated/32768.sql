WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.role_id IS NOT NULL

    UNION ALL

    SELECT 
        c.person_id, 
        c.movie_id, 
        ah.level + 1
    FROM 
        cast_info c
    INNER JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    WHERE 
        c.person_id <> ah.person_id
), RankedActors AS (
    SELECT 
        a.person_id, 
        COUNT(DISTINCT a.movie_id) AS movie_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT a.movie_id) DESC) AS actor_rank
    FROM 
        ActorHierarchy a
    GROUP BY 
        a.person_id
), CompanyDetails AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
), MovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COALESCE(MAX(mi.info), 'No Information') AS movie_info
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
)
SELECT 
    ra.actor_rank,
    ra.person_id,
    ak.name AS actor_name,
    mv.title,
    mv.production_year,
    cd.company_count,
    cd.company_names,
    mv.movie_info
FROM 
    RankedActors ra
JOIN 
    aka_name ak ON ra.person_id = ak.person_id
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    CompanyDetails cd ON ci.movie_id = cd.movie_id
JOIN 
    MovieInfo mv ON ci.movie_id = mv.title_id
WHERE 
    mv.production_year BETWEEN 2000 AND 2023
    AND cd.company_count > 1
ORDER BY 
    ra.actor_rank;
