WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        a.name IS NOT NULL AND
        t.production_year IS NOT NULL
),
ActorStats AS (
    SELECT 
        actor_name,
        COUNT(*) AS total_movies,
        MIN(production_year) AS first_movie_year,
        MAX(production_year) AS last_movie_year
    FROM 
        RankedMovies
    GROUP BY 
        actor_name
)
SELECT 
    as.actor_name,
    as.total_movies,
    as.first_movie_year,
    as.last_movie_year,
    CASE 
        WHEN as.total_movies > 10 THEN 'Veteran Actor'
        WHEN as.total_movies BETWEEN 5 AND 10 THEN 'Established Actor'
        ELSE 'Newcomer Actor'
    END AS actor_category
FROM 
    ActorStats as
WHERE 
    as.first_movie_year IS NOT NULL
ORDER BY 
    as.total_movies DESC,
    as.actor_name ASC;

-- Subquery to find movies that have more than one keyword
SELECT DISTINCT 
    m.title,
    k.keyword
FROM 
    aka_title m
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    m.title, k.keyword
HAVING 
    COUNT(mk.keyword_id) > 1
ORDER BY 
    m.title;

-- Full Outer Join Example to list all companies involved in production or distribution
SELECT 
    cn.name AS company_name,
    ct.kind AS company_type,
    mc.note AS movie_note
FROM 
    company_name cn
FULL OUTER JOIN 
    movie_companies mc ON cn.id = mc.company_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    cn.name IS NOT NULL OR mc.movie_id IS NOT NULL
ORDER BY 
    cn.name, mc.movie_id;

-- Finding actors who have played in all movies before 2000 that have a certain keyword
SELECT 
    DISTINCT a.name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
WHERE 
    t.production_year < 2000 AND t.id IN (
        SELECT 
            mk.movie_id
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        WHERE 
            k.keyword = 'Drama'
    )
ORDER BY 
    a.name;
