WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY m.id DESC) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies,
        COALESCE(k.keyword, 'No keywords') AS keywords
    FROM 
        aka_title AS t
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    INNER JOIN 
        movie_info AS mi ON t.id = mi.movie_id
    INNER JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    INNER JOIN 
        company_name AS c ON mc.company_id = c.id
    WHERE 
        t.production_year IS NOT NULL
        AND k.keyword IS NOT NULL
        AND c.country_code = 'USA'
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        r.role AS person_role,
        COUNT(*) OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_count
    FROM 
        cast_info AS ci
    JOIN 
        role_type AS r ON ci.role_id = r.id
    WHERE 
        ci.nr_order < 5
),
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        fl.person_role,
        CASE 
            WHEN rm.total_movies > 10 THEN 'Popular'
            ELSE 'Less Popular'
        END AS movie_category,
        COALESCE(fc.role_count, 0) AS main_cast_count
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        FilteredCast AS fc ON rm.movie_id = fc.movie_id
)
SELECT 
    md.title,
    md.production_year,
    GROUP_CONCAT(DISTINCT md.person_role ORDER BY md.person_role) AS roles,
    md.movie_category,
    md.main_cast_count
FROM 
    MovieDetails AS md
GROUP BY 
    md.title, md.production_year, md.movie_category, md.main_cast_count
HAVING 
    COUNT(DISTINCT md.person_role) > 1 
ORDER BY 
    md.production_year DESC, md.main_cast_count DESC;
