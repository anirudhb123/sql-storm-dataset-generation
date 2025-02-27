WITH MovieCount AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT ca.movie_id) AS movie_count,
        SUM(CASE WHEN ca.note IS NULL THEN 1 ELSE 0 END) AS null_notes
    FROM 
        cast_info ca
    INNER JOIN 
        aka_name a ON ca.person_id = a.person_id
    LEFT JOIN 
        title t ON ca.movie_id = t.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        c.person_id
),
TopMovies AS (
    SELECT 
        mc.person_id,
        mc.movie_count,
        ROW_NUMBER() OVER (ORDER BY mc.movie_count DESC) AS rank
    FROM 
        MovieCount mc
    WHERE 
        mc.movie_count > 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    ci.company_name,
    ci.company_type,
    tc.movie_count,
    COALESCE(tc.null_notes, 0) AS null_notes_count
FROM 
    aka_name a
JOIN 
    cast_info ca ON a.person_id = ca.person_id
JOIN 
    title m ON ca.movie_id = m.id
JOIN 
    TopMovies tc ON a.person_id = tc.person_id
LEFT JOIN 
    CompanyInfo ci ON m.id = ci.movie_id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'short'))
ORDER BY 
    tc.movie_count DESC, m.production_year ASC;
