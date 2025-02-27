WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
AverageRoleCounts AS (
    SELECT 
        c.role_id,
        COUNT(*) AS avg_role_count
    FROM 
        cast_info c
    JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    GROUP BY 
        c.role_id
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(ar.avg_role_count, 0) AS average_roles,
    ak.name AS actor_name,
    ak.name_pcode_nf,
    CASE 
        WHEN mc.note IS NULL THEN 'No Note'
        ELSE mc.note
    END AS company_note
FROM 
    TopMovies tm
LEFT JOIN 
    movie_companies mc ON tm.production_year = mc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id IN (
        SELECT DISTINCT c.person_id 
        FROM cast_info c 
        WHERE c.movie_id = tm.title
    )
LEFT JOIN 
    AverageRoleCounts ar ON ak.id = ar.role_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, 
    tm.title;
