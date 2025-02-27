WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        a.id AS movie_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY RANDOM()) AS rn,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        COALESCE(cmn.country_code, 'Unknown Country') AS company_country
    FROM 
        aka_title a
        LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
        LEFT JOIN movie_companies mc ON a.id = mc.movie_id
        LEFT JOIN company_name cmn ON mc.company_id = cmn.id
    WHERE 
        a.production_year IS NOT NULL
),
actor_movies AS (
    SELECT 
        ki.id AS keyword_id,
        p.id AS person_id,
        r.role,
        m.title AS movie_title,
        m.production_year
    FROM 
        cast_info ci
        JOIN role_type r ON ci.role_id = r.id
        JOIN aka_name p ON ci.person_id = p.person_id
        JOIN aka_title m ON ci.movie_id = m.id
        LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
        LEFT JOIN keyword ki ON mk.keyword_id = ki.id
    WHERE 
        p.name IS NOT NULL
),
filtered_movies AS (
    SELECT 
        rm.title,
        rm.production_year,
        am.person_id,
        am.movie_title,
        RM.movie_keyword,
        rm.company_country
    FROM 
        ranked_movies rm
        LEFT JOIN actor_movies am ON rm.title = am.movie_title AND rm.production_year = am.production_year
    WHERE 
        (rm.company_country IS NOT NULL OR rm.movie_keyword <> 'No Keyword')
        AND (rm.rn <= 10 OR am.person_id IS NOT NULL)
)
SELECT 
    COUNT(DISTINCT fm.movie_title) AS total_movies,
    fm.company_country,
    STRING_AGG(DISTINCT fm.movie_keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT p.name, ', ') AS actors_in_movies
FROM 
    filtered_movies fm
    LEFT JOIN aka_name p ON fm.person_id = p.person_id
GROUP BY 
    fm.company_country
HAVING 
    COUNT(DISTINCT fm.movie_title) > 5
ORDER BY 
    total_movies DESC;
