WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS named_roles,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),

FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_cast,
        rm.named_roles
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 
),

NullHandling AS (
    SELECT 
        fm.title,
        fm.production_year,
        COALESCE(fm.total_cast, 0) AS cast_count,
        COALESCE(fm.named_roles, 0) AS named_roles_count
    FROM 
        FilteredMovies fm
)

SELECT 
    nh.title,
    nh.production_year,
    nh.cast_count,
    nh.named_roles_count,
    CASE 
        WHEN nh.cast_count > nh.named_roles_count THEN 'More total cast than named roles'
        WHEN nh.cast_count < nh.named_roles_count THEN 'More named roles than total cast'
        ELSE 'Total cast equals named roles'
    END AS cast_analysis,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    COUNT(DISTINCT mi.info) AS movie_info_count
FROM 
    NullHandling nh
LEFT JOIN 
    movie_companies mc ON nh.production_year = mc.movie_id  
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = nh.production_year
WHERE 
    cn.country_code IS NOT NULL OR nh.production_year > 2000
GROUP BY 
    nh.title, nh.production_year, nh.cast_count, nh.named_roles_count
HAVING 
    COUNT(DISTINCT mi.info) > 1 
ORDER BY 
    nh.production_year DESC, nh.cast_count DESC
LIMIT 10;