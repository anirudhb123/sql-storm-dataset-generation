WITH Recursive ActorMovies AS (
    SELECT 
        c.person_id,
        c.movie_id,
        ROW_NUMBER() OVER (PARTITION BY c.person_id ORDER BY a.id) AS movie_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
ActorRoleCount AS (
    SELECT 
        person_id,
        COUNT(DISTINCT role_id) AS total_roles
    FROM 
        cast_info
    GROUP BY 
        person_id
),
RolePopularity AS (
    SELECT 
        role_id,
        COUNT(*) AS role_count
    FROM 
        cast_info
    GROUP BY 
        role_id
),
MoviesYearly AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies
    FROM 
        aka_title
    GROUP BY 
        production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithHighestKeywords AS (
    SELECT 
        movie_id,
        keywords,
        ROW_NUMBER() OVER (ORDER BY LENGTH(keywords) DESC) AS rank
    FROM 
        MovieKeywords
)
SELECT 
    a.name,
    am.movie_id,
    t.title,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    COALESCE(m.total_movies, 0) AS total_movies,
    r.total_roles,
    CASE 
        WHEN r.total_roles > 5 THEN 'Veteran Actor' 
        WHEN r.total_roles BETWEEN 2 AND 5 THEN 'Intermediate Actor' 
        ELSE 'New Actor' 
    END AS actor_experience,
    RANK() OVER (ORDER BY m.total_movies DESC) AS movie_rank
FROM 
    aka_name a
JOIN 
    ActorMovies am ON a.person_id = am.person_id
JOIN 
    aka_title t ON am.movie_id = t.id
LEFT JOIN 
    MoviesWithHighestKeywords k ON am.movie_id = k.movie_id
LEFT JOIN 
    MoviesYearly m ON t.production_year = m.production_year
JOIN 
    ActorRoleCount r ON a.person_id = r.person_id
WHERE 
    t.production_year IS NOT NULL
    AND (r.total_roles >= 1 OR am.movie_order <= 3)
ORDER BY 
    movie_rank, actor_experience DESC;

