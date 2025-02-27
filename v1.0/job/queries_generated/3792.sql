WITH RecursiveDirector AS (
    SELECT 
        p.id AS person_id,
        a.name AS director_name,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON ci.person_id = a.person_id
    JOIN 
        title m ON m.id = ci.movie_id
    WHERE 
        ci.person_role_id = (SELECT id FROM role_type WHERE role = 'director')
    GROUP BY 
        p.id, a.name
),
TopDirectors AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY movie_count DESC) AS rank
    FROM 
        RecursiveDirector
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        GROUP_CONCAT(k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    td.director_name,
    mwk.title,
    mwk.keywords,
    td.movie_count
FROM 
    TopDirectors td
JOIN 
    MoviesWithKeywords mwk ON td.person_id IN (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = mwk.movie_id
    )
WHERE 
    td.rank <= 10
ORDER BY 
    td.movie_count DESC, mwk.title ASC;
