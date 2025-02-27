WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COUNT(DISTINCT c.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS starring_roles,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type rt ON c.role_id = rt.id
    LEFT JOIN 
        aka_name an ON c.person_id = an.person_id
    WHERE 
        a.production_year IS NOT NULL AND 
        a.production_year >= 2000
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year, 
        total_cast, 
        starring_roles
    FROM 
        RankedMovies
    WHERE 
        total_cast > 5 AND 
        starring_roles > 2
)
SELECT 
    t.title AS Movie_Title, 
    t.production_year AS Released_Year, 
    t.total_cast AS Total_Cast_Members, 
    t.starring_roles AS Leading_Roles, 
    COALESCE(NULLIF(STRING_AGG(an.name, ', '), ''), 'No Cast Available') AS Cast_Names
FROM 
    TopMovies t
LEFT JOIN 
    cast_info c ON t.title = c.movie_id
LEFT JOIN 
    aka_name an ON c.person_id = an.person_id
GROUP BY 
    t.title, t.production_year, t.total_cast, t.starring_roles
HAVING 
    COUNT(an.id) > 0
ORDER BY 
    t.production_year DESC, t.starring_roles DESC;
