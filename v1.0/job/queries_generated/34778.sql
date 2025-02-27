WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ka.id AS actor_id,
        ka.name AS actor_name,
        0 AS level
    FROM 
        aka_name ka
    WHERE 
        ka.name IS NOT NULL
    UNION ALL
    SELECT 
        ka.id,
        ka.name,
        ah.level + 1
    FROM 
        aka_name ka
    INNER JOIN 
        cast_info ci ON ka.person_id = ci.person_id
    INNER JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.actor_id
    WHERE 
        ka.name IS NOT NULL
), RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 -- Top 5 movies per production year
)
SELECT 
    f.title,
    f.production_year,
    a.actor_name,
    CASE 
        WHEN ci.note IS NULL THEN 'No Note' 
        ELSE ci.note 
    END AS role_note,
    COALESCE(g.kind, 'Unknown') AS genre
FROM 
    FilteredMovies f
LEFT JOIN 
    cast_info ci ON f.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_type g ON mc.company_type_id = g.id
WHERE 
    f.production_year > 2000 
    AND a.actor_name LIKE '%Smith%' -- Actor filter example
ORDER BY 
    f.production_year DESC, 
    f.title ASC;
