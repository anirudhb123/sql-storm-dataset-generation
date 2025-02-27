
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        cast_info c
        INNER JOIN role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
    GROUP BY 
        c.movie_id, r.role
), 
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
        LEFT JOIN company_name co ON mc.company_id = co.id
        LEFT JOIN company_type ct ON mc.company_type_id = ct.id
), 
TitleInfo AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(m.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        INNER JOIN keyword m ON mk.keyword_id = m.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    mr.role,
    mr.total_cast,
    ci.company_name,
    ci.company_type,
    ti.keywords,
    CASE 
        WHEN COUNT(mr.total_cast) > 10 THEN 'Large Cast'
        ELSE 'Smaller Cast'
    END AS cast_size_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieRoles mr ON rm.movie_id = mr.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    TitleInfo ti ON rm.movie_id = ti.movie_id
GROUP BY 
    rm.title, 
    rm.production_year, 
    mr.role, 
    mr.total_cast, 
    ci.company_name, 
    ci.company_type, 
    ti.keywords
HAVING 
    rm.production_year >= 2000 
    AND (mr.total_cast IS NOT NULL OR ci.company_name IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
