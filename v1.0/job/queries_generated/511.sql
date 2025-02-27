WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY count(c.movie_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title, production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
PersonRoles AS (
    SELECT 
        ci.role_id,
        COUNT(DISTINCT ci.person_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.role_id
)
SELECT 
    tm.title,
    tm.production_year,
    COALESCE(pr.role_count, 0) AS unique_role_count,
    (SELECT COUNT(*) FROM aka_name an WHERE an.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1))) AS actor_count,
    STRING_AGG(DISTINCT an.name, ', ') AS actor_names
FROM 
    TopMovies tm
LEFT JOIN 
    PersonRoles pr ON pr.role_id = (SELECT id FROM role_type WHERE role = 'Actor' LIMIT 1)
LEFT JOIN 
    cast_info ci ON ci.movie_id = (SELECT id FROM aka_title WHERE title = tm.title LIMIT 1)
LEFT JOIN 
    aka_name an ON ci.person_id = an.person_id
GROUP BY 
    tm.title, tm.production_year, pr.role_count
ORDER BY 
    tm.production_year DESC, tm.title;
