WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorsWithInfo AS (
    SELECT 
        a.name, 
        i.info,
        CASE 
            WHEN a.gender IS NULL THEN 'Unknown'
            ELSE a.gender 
        END AS gender
    FROM 
        name a
    LEFT JOIN 
        person_info i ON a.imdb_id = i.person_id
    WHERE 
        a.md5sum IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    rm.num_actors,
    ARRAY_AGG(DISTINCT a.name) AS actor_names,
    COUNT(DISTINCT a.gender) AS distinct_genders
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
LEFT JOIN 
    ActorsWithInfo a ON ci.person_id = a.name
WHERE 
    rm.rank <= 5 
GROUP BY 
    rm.title, rm.production_year, rm.num_actors
ORDER BY 
    rm.production_year DESC, rm.num_actors DESC
LIMIT 10;

-- Example for benchmarking with various SQL constructs
SELECT 
    coalesce(ct.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT mc.movie_id) AS total_movies,
    SUM(CASE WHEN m.production_year > 2000 THEN 1 ELSE 0 END) AS movies_after_2000
FROM 
    movie_companies mc
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    aka_title m ON mc.movie_id = m.id
GROUP BY 
    coalesce(ct.kind, 'Unknown')
HAVING 
    COUNT(DISTINCT mc.movie_id) > 10
ORDER BY 
    total_movies DESC;
