WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
PersonRoles AS (
    SELECT
        ci.person_id,
        rt.role,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role IS NOT NULL
    GROUP BY 
        ci.person_id, rt.role
),
TopActors AS (
    SELECT 
        pr.person_id,
        pr.role,
        RANK() OVER (ORDER BY SUM(pr.movie_count) DESC) AS actor_rank
    FROM 
        PersonRoles pr
    GROUP BY 
        pr.person_id, pr.role
)
SELECT 
    ak.name AS actor_name,
    tm.title AS movie_title,
    tm.production_year,
    tar.role AS actor_role,
    COUNT(DISTINCT mi.info) AS keyword_count,
    SUM(CASE 
            WHEN mi.note IS NOT NULL THEN 1 
            ELSE 0 
        END) AS note_count
FROM 
    RankedMovies tm
JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
JOIN 
    TopActors tar ON ak.person_id = tar.person_id
LEFT JOIN 
    movie_keyword mk ON tm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')
WHERE 
    (tm.production_year >= 2000 OR (tm.production_year < 2000 AND tar.actor_rank <= 5))
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name, tm.title, tm.production_year, tar.role
HAVING 
    COUNT(DISTINCT mk.keyword_id) > 2
ORDER BY 
    tm.production_year DESC, actor_name, keyword_count DESC;
