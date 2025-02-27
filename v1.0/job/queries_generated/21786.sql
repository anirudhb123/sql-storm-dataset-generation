WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY at.id) AS actor_count,
        SUM(CASE WHEN ci.note LIKE '%lead%' THEN 1 ELSE 0 END) OVER (PARTITION BY at.id) AS lead_actor_count,
        STRING_AGG(DISTINCT a.name, ', ') FILTER (WHERE a.name IS NOT NULL) OVER (PARTITION BY at.id) AS actor_names
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        at.production_year IS NOT NULL
), MovieStatistics AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_count,
        lead_actor_count,
        actor_names,
        CASE 
            WHEN actor_count > 0 THEN (lead_actor_count::float / actor_count) * 100
            ELSE NULL 
        END AS lead_actor_percentage
    FROM 
        RankedMovies
), FilteredMovies AS (
    SELECT 
        ms.movie_id,
        ms.title,
        ms.production_year,
        ms.actor_count,
        ms.lead_actor_count,
        ms.actor_names,
        ms.lead_actor_percentage
    FROM 
        MovieStatistics ms
    WHERE 
        (ms.lead_actor_percentage IS NULL OR ms.lead_actor_percentage > 10)
        AND ms.actor_count >= 5
)

SELECT 
    fm.title,
    fm.production_year,
    fm.actor_count,
    fm.lead_actor_count,
    fm.lead_actor_percentage,
    CASE 
        WHEN fm.actor_count > 20 THEN 'High Cast'
        WHEN fm.actor_count BETWEEN 10 AND 20 THEN 'Medium Cast'
        ELSE 'Low Cast' 
    END AS cast_size
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC,
    fm.lead_actor_percentage DESC;

-- Second part including additional complex aggregation with NULL handling and exotic joins
SELECT 
    t.title,
    COUNT(DISTINCT m.id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name) AS companies,
    COUNT(DISTINCT (SELECT mk.keyword FROM movie_keyword mk WHERE mk.movie_id = t.id AND mk.keyword IS NOT NULL)) AS keyword_count
FROM 
    title t
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    (mi.info IS NOT NULL AND mi.note IS NOT NULL)
GROUP BY 
    t.id
HAVING 
    COUNT(DISTINCT (SELECT m.id FROM movie_info m WHERE m.movie_id = t.id AND m.info IS NOT NULL)) > 5
ORDER BY 
    company_count DESC, 
    keyword_count ASC;

-- Final options including a random pick of titles
SELECT DISTINCT 
    t.title AS random_title
FROM 
    title t
WHERE 
    RANDOM() < 0.1
ORDER BY 
    RANDOM()
LIMIT 5;
