WITH RecursiveMovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        c.movie_id,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
TitleWithCompanyCounts AS (
    SELECT 
        m.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    GROUP BY 
        m.id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.title_rank,
    r.total_movies,
    COALESCE(ci.cast_count, 0) AS cast_count,
    COALESCE(ci.roles, 'No Roles') AS roles,
    COALESCE(cc.company_count, 0) AS company_count
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    CastInfoWithRoles ci ON r.movie_id = ci.movie_id
LEFT JOIN 
    TitleWithCompanyCounts cc ON r.movie_id = cc.movie_id
WHERE 
    r.production_year >= (SELECT MAX(production_year) FROM aka_title WHERE production_year IS NOT NULL) - 5
    AND r.title LIKE '%' || (SELECT keyword FROM keyword WHERE id = (SELECT MIN(id) FROM keyword)) || '%'
ORDER BY 
    r.production_year DESC, 
    r.title_rank
LIMIT 100 OFFSET 0;

-- Additional component to highlight NULL handling and edge cases
SELECT 
    m.id AS movie_id,
    m.title,
    CASE 
        WHEN ci.cast_count IS NULL THEN 'No cast information available.' 
        ELSE CONCAT(ci.cast_count, ' cast members')
    END AS cast_info,
    COUNT(DISTINCT kl.id) AS keyword_count,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM movie_info mi 
            WHERE mi.movie_id = m.id AND mi.info_type_id = (SELECT MAX(id) FROM info_type)
        ) THEN 'Has latest info type'
        ELSE 'No info of latest type'
    END AS latest_info_status
FROM 
    aka_title m
LEFT JOIN 
    CastInfoWithRoles ci ON m.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword kl ON mk.keyword_id = kl.id
GROUP BY 
    m.id, m.title, ci.cast_count
HAVING 
    cast_info != 'No cast information available.'
ORDER BY 
    keyword_count DESC;

-- Using an unusual behavior with OUTER JOINs while filtering NULLs
SELECT 
    t.id AS title_id,
    t.title,
    c.name AS company_name,
    mi.info AS additional_info
FROM 
    aka_title t
FULL OUTER JOIN 
    movie_companies mc ON t.id = mc.movie_id
FULL OUTER JOIN 
    company_name c ON mc.company_id = c.id
FULL OUTER JOIN 
    movie_info mi ON t.id = mi.movie_id 
WHERE 
    (
        (c.country_code IS NULL OR c.country_code <> 'USA')
        AND (mi.info_type_id IS NULL OR mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE 'Description%'))
    )
ORDER BY 
    t.title;

