WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorRoles AS (
    SELECT 
        ak.name AS actor_name,
        role.role AS role_name,
        c.movie_id,
        t.title
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type role ON c.role_id = role.id
    JOIN 
        title t ON c.movie_id = t.id
)
SELECT 
    tm.title AS Movie_Title,
    tm.production_year AS Production_Year,
    ar.actor_name AS Actor_Name,
    ar.role_name AS Role_Name,
    COALESCE(c.name, 'Unknown Company') AS Company_Name,
    CASE 
        WHEN mk.keyword_id IS NOT NULL THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS Keyword_Status
FROM 
    TopMovies tm
LEFT JOIN 
    ActorRoles ar ON tm.title_id = ar.movie_id
LEFT JOIN 
    movie_companies mc ON tm.title_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON tm.title_id = mk.movie_id
WHERE 
    tm.production_year IS NOT NULL
ORDER BY 
    tm.production_year DESC, tm.title;
