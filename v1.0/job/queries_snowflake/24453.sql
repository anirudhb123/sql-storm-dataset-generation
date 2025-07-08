WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.role_id) AS unique_roles,
        MAX(CASE 
            WHEN c.gender = 'M' THEN 1 
            WHEN c.gender = 'F' THEN 0 
            ELSE NULL 
        END) AS male_ratio
    FROM 
        cast_info ci
    JOIN 
        name c ON ci.person_id = c.id
    GROUP BY 
        ci.movie_id
),
MoviesWithInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title, 
        mt.production_year,
        COALESCE(mi.info, 'No Info Available') AS movie_info,
        cb.unique_roles,
        cb.male_ratio
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_info mi ON mt.id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    LEFT JOIN 
        CastRoles cb ON mt.id = cb.movie_id
)
SELECT 
    mw.title,
    mw.production_year,
    mw.movie_info,
    CASE 
        WHEN mw.unique_roles IS NULL THEN 'Role data unavailable' 
        ELSE CONCAT('Unique roles: ', mw.unique_roles) 
    END AS role_data,
    CASE 
        WHEN mw.male_ratio IS NULL THEN 'Gender distribution unknown' 
        ELSE 
            CASE 
                WHEN mw.male_ratio = 1 THEN 'All male cast'
                WHEN mw.male_ratio = 0 THEN 'All female cast'
                ELSE CONCAT('Mixed gender cast - Male ratio: ', mw.male_ratio)
            END 
    END AS gender_distribution
FROM 
    MoviesWithInfo mw
WHERE 
    mw.production_year > 2000
    AND mw.movie_info IS NOT NULL
ORDER BY 
    mw.production_year DESC, 
    mw.title;
