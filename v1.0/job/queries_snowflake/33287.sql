
WITH RECURSIVE MovieRank AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title AS t
    WHERE 
        t.production_year IS NOT NULL
),
ActorsWithRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(c.id) AS role_count
    FROM 
        cast_info AS c
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    JOIN 
        role_type AS r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, a.name, r.role
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title AS m
    LEFT JOIN 
        movie_keyword AS mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    t.title, 
    t.production_year, 
    a.actor_name, 
    a.role_name,
    mw.keywords,
    COALESCE(mr.year_rank, NULL) AS rank_in_year
FROM 
    aka_title t
LEFT JOIN 
    ActorsWithRoles a ON t.id = a.movie_id
LEFT JOIN 
    MoviesWithKeywords mw ON t.id = mw.movie_id
LEFT JOIN 
    MovieRank mr ON t.id = mr.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND (a.role_name LIKE '%lead%' OR a.role_name LIKE '%star%')
ORDER BY 
    t.production_year DESC, 
    mr.year_rank ASC,
    a.actor_name;
