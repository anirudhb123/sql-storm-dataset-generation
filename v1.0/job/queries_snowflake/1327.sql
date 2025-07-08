
WITH MovieRoles AS (
    SELECT 
        m.title, 
        m.production_year, 
        c.person_id,
        r.role,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY c.nr_order) AS role_order,
        m.id AS movie_id
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        m.production_year >= 2000
),
TopMovies AS (
    SELECT 
        movie_id,
        COUNT(*) AS role_count
    FROM 
        MovieRoles
    GROUP BY 
        movie_id
    HAVING 
        COUNT(*) > 3
),
ExtendedInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(SUM(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END), 0) AS info_type_count,
        MAX(m.production_year) AS latest_year
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
    JOIN 
        TopMovies t ON m.id = t.movie_id
    GROUP BY 
        m.id, m.title
)
SELECT 
    e.title,
    e.latest_year,
    r.person_id,
    r.role,
    r.role_order,
    k.keyword,
    ct.kind AS company_type,
    COUNT(DISTINCT mc.company_id) AS companies_involved
FROM 
    ExtendedInfo e
JOIN 
    MovieRoles r ON e.movie_id = r.movie_id
LEFT JOIN 
    movie_companies mc ON e.movie_id = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON e.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    r.role_order <= 2 
GROUP BY 
    e.title, e.latest_year, r.person_id, r.role, r.role_order, k.keyword, ct.kind
ORDER BY 
    e.latest_year DESC, e.title;
