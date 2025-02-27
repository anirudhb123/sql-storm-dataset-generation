WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(k.keyword) AS keyword_count,
        DENSE_RANK() OVER (PARTITION BY t.kind_id ORDER BY COUNT(k.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
MoviesWithCast AS (
    SELECT 
        m.title,
        m.production_year,
        COALESCE(c.person_id, -1) AS person_id,
        RANK() OVER (PARTITION BY m.title ORDER BY c.nr_order) AS role_order
    FROM 
        RankedMovies m
    LEFT JOIN 
        complete_cast cc ON m.title = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        person_id
    FROM 
        MoviesWithCast
    WHERE 
        person_id IS NOT NULL
)
SELECT 
    f.title,
    f.production_year,
    a.name AS actor_name,
    COALESCE(c.kind, 'Unknown') AS company_type,
    COUNT(DISTINCT ci.id) FILTER (WHERE ci.note IS NOT NULL) AS non_null_notes
FROM 
    FilteredMovies f
LEFT JOIN 
    aka_name a ON f.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON f.movie_id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    cast_info ci ON f.person_id = ci.person_id AND f.title = (SELECT title FROM aka_title WHERE id = ci.movie_id)
WHERE 
    f.production_year >= 2000
GROUP BY 
    f.title, f.production_year, a.name, c.kind
HAVING 
    AVG(role_order) > 1
ORDER BY 
    keyword_count DESC NULLS LAST;
