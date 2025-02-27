WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(r.role, 'Unknown') AS role,
        COUNT(c.person_id) OVER (PARTITION BY m.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY m.id) AS rn
    FROM 
        aka_title AS t
    JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    LEFT JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info AS c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type AS r ON c.role_id = r.id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary') 
        AND t.production_year >= 2000
),
ActorInfoCTE AS (
    SELECT 
        a.person_id,
        ak.name AS actor_name,
        STRING_AGG(DISTINCT m.title, ', ') AS movies,
        COUNT(DISTINCT m.id) AS movie_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        aka_name AS ak
    JOIN 
        cast_info AS c ON ak.person_id = c.person_id
    JOIN 
        RecursiveMovieCTE AS m ON c.movie_id = m.movie_id
    LEFT JOIN 
        role_type AS r ON c.role_id = r.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        a.person_id, ak.name
),
CompanyMoviesCTE AS (
    SELECT 
        m.movie_id,
        c.company_id,
        co.name AS company_name,
        COALESCE(mk.keyword, 'N/A') as movie_keyword
    FROM 
        movie_companies AS m
    JOIN 
        company_name AS co ON m.company_id = co.id
    LEFT JOIN 
        movie_keyword AS mk ON mk.movie_id = m.movie_id
    WHERE 
        co.country_code = 'USA'
)
SELECT 
    a.actor_name,
    a.movie_count,
    a.roles,
    COUNT(DISTINCT cm.company_id) AS total_companies,
    COUNT(DISTINCT cm.movie_id) AS total_movies_by_companies,
    STRING_AGG(DISTINCT cm.movie_keyword, ', ') AS all_keywords,
    MAX(m.production_year) AS latest_movie_year
FROM 
    ActorInfoCTE AS a
JOIN 
    cast_info AS c ON a.person_id = c.person_id
JOIN 
    RecursiveMovieCTE AS m ON c.movie_id = m.movie_id
LEFT JOIN 
    CompanyMoviesCTE AS cm ON m.movie_id = cm.movie_id
WHERE 
    a.movie_count > 5
GROUP BY 
    a.actor_name, a.movie_count, a.roles
HAVING 
    MAX(m.production_year) < 2023
    AND COUNT(DISTINCT cm.company_id) > 3
ORDER BY 
    a.movie_count DESC, a.actor_name
LIMIT 100;
