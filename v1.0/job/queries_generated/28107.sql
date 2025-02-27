WITH RankedTitles AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title AS a
    JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
),
CastWithRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role AS person_role,
        p.name AS person_name
    FROM 
        cast_info AS c
    JOIN 
        role_type AS r ON c.role_id = r.id
    JOIN 
        aka_name AS p ON c.person_id = p.person_id
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        title AS t
    JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
)
SELECT 
    m.title,
    m.production_year,
    r.person_name,
    r.person_role,
    COALESCE(kw.keywords, 'No keywords') AS keywords
FROM 
    MoviesWithKeywords AS m
LEFT JOIN 
    CastWithRoles AS r ON m.title_id = r.movie_id
LEFT JOIN 
    RankedTitles AS kw ON m.title_id = kw.movie_title
WHERE 
    kw.year_rank = 1
ORDER BY 
    m.production_year DESC,
    m.title;
