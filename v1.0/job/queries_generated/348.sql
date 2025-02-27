WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS rn
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(c.nr_order) OVER (PARTITION BY c.movie_id) AS total_cast
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
),
MovieStats AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_actors,
        AVG(COALESCE(m.year_count, 1)) AS avg_years_active
    FROM 
        complete_cast m
    LEFT JOIN 
        CastInfoWithRoles c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id
)
SELECT 
    rm.title,
    rm.production_year,
    ms.total_actors,
    ms.avg_years_active,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT c.id) AS company_count
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    MovieStats ms ON rm.production_year = ms.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    (rm.rn <= 5 OR ms.total_actors > 10) AND 
    (c.country_code IS NOT NULL OR c.country_code IS NULL)
GROUP BY 
    rm.title, rm.production_year, ms.total_actors, ms.avg_years_active
ORDER BY 
    rm.production_year DESC, total_actors DESC;
