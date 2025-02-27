WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast_size
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_by_cast_size <= 5
),
MovieGenres AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(DISTINCT g.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword g ON mk.keyword_id = g.id
    JOIN 
        TopMovies mt ON mk.movie_id = mt.movie_id
    GROUP BY 
        mt.movie_id
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        MIN(r.role) AS primary_role,
        MAX(CASE WHEN r.role = 'Lead' THEN c.note ELSE NULL END) AS lead_note
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(mg.genres, 'No Genre') AS genres,
    ar.actor_count,
    ar.primary_role,
    CASE 
        WHEN ar.lead_note IS NOT NULL THEN 'Lead Actor Note: ' || ar.lead_note
        ELSE 'No Lead Actor Note'
    END AS lead_actor_note
FROM 
    TopMovies tm
LEFT JOIN 
    MovieGenres mg ON tm.movie_id = mg.movie_id
LEFT JOIN 
    ActorRoles ar ON tm.movie_id = ar.movie_id
WHERE 
    tm.production_year >= 2000 AND
    (tm.title ILIKE '%Adventure%' OR tm.title ILIKE '%Fantasy%')
ORDER BY 
    tm.production_year DESC, 
    ar.actor_count DESC
LIMIT 10;

-- Enhanced Numeric Null Logic
SELECT 
    c.movie_id,
    COUNT(*) AS total_cast,
    AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE NULL END) AS lead_actor_ratio
FROM 
    cast_info c
JOIN 
    aka_title m ON c.movie_id = m.id
WHERE 
    m.production_year IS NOT NULL
GROUP BY 
    c.movie_id
HAVING 
    COUNT(*) > 5 OR COUNT(*) IS NULL
ORDER BY 
    lead_actor_ratio DESC;

-- Using Set Operators
SELECT 
    DISTINCT title, 'Top Titles' AS category
FROM 
    aka_title
WHERE 
    production_year > 2010
UNION
SELECT 
    DISTINCT title, 'Older Titles' AS category
FROM 
    aka_title
WHERE 
    production_year <= 2010
ORDER BY 
    category, title;

-- Comprehensive NULL Logic Check
SELECT 
    DISTINCT m.title,
    m.production_year,
    m.id,
    COALESCE(ar.primary_role, 'No Roles Found') AS role_found,
    CASE 
        WHEN mk.keyword IS NULL THEN 'No Keywords Assigned' 
        ELSE 'Keywords Present' 
    END AS keyword_status
FROM 
    aka_title m
LEFT JOIN 
    MovieGenres mk ON m.id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON m.id = ar.movie_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
ORDER BY 
    m.production_year DESC, 
    m.title;
