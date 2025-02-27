WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
ActorWithMultipleRoles AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.role_id) as role_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.person_id
    HAVING 
        COUNT(DISTINCT c.role_id) > 1
),
MoviesWithStarPower AS (
    SELECT 
        rm.title,
        rm.production_year,
        ar.person_id,
        ar.roles,
        CASE 
            WHEN rm.total_movies > 5 THEN 'High 
            Output'
            ELSE 'Low Output'
        END AS output_level
    FROM 
        RankedMovies rm
    JOIN 
        ActorWithMultipleRoles ar ON rm.keyword LIKE '%' || ar.roles || '%'
    WHERE 
        rm.rn <= 10
)
SELECT 
    mw.title,
    mw.production_year,
    mw.roles,
    mw.output_level,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    (SELECT COUNT(*) 
     FROM movie_companies mc 
     WHERE mc.movie_id = (SELECT id FROM aka_title WHERE title = mw.title LIMIT 1)) AS company_count
FROM 
    MoviesWithStarPower mw
LEFT JOIN 
    movie_companies mc ON mw.title = (SELECT title FROM aka_title WHERE id = mc.movie_id LIMIT 1)
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mw.output_level = 'High Output'
    AND mw.production_year > (SELECT MAX(production_year) FROM aka_title WHERE title IS NOT NULL)
ORDER BY 
    mw.production_year DESC, 
    mw.roles;
