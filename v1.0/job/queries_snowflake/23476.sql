
WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, rt.role
),
ComplexMovieData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cr.role, 'Unknown') AS role,
        cr.role_count,
        CASE 
            WHEN rm.rank = 1 THEN 'Top'
            ELSE 'Other'
        END AS rank_category,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = rm.movie_id) AS keyword_count,
        (SELECT LISTAGG(DISTINCT cn.name, ', ') 
         WITHIN GROUP (ORDER BY cn.name)
         FROM movie_companies mc 
         JOIN company_name cn ON mc.company_id = cn.id 
         WHERE mc.movie_id = rm.movie_id) AS production_companies
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastRoles cr ON rm.movie_id = cr.movie_id
)
SELECT 
    cmd.title,
    cmd.production_year,
    cmd.role,
    cmd.role_count,
    cmd.rank_category,
    cmd.keyword_count,
    cmd.production_companies,
    CASE 
        WHEN cmd.production_year < 2000 THEN 'Classic'
        WHEN cmd.production_year BETWEEN 2000 AND 2010 THEN 'Modern Classic'
        ELSE 'Recent'
    END AS era,
    (SELECT AVG(word_length) 
     FROM (SELECT LENGTH(word) AS word_length 
           FROM TABLE(FLATTEN(INPUT => SPLIT(cmd.title, ' '))) AS word) AS lengths) AS avg_word_length,
    CASE 
        WHEN cmd.role_count IS NULL THEN 'No Roles Detected'
        ELSE 'Roles Detected'
    END AS role_status
FROM 
    ComplexMovieData cmd
WHERE 
    cmd.production_year IS NOT NULL
GROUP BY 
    cmd.title, 
    cmd.production_year, 
    cmd.role, 
    cmd.role_count, 
    cmd.rank_category, 
    cmd.keyword_count, 
    cmd.production_companies
ORDER BY 
    cmd.production_year DESC, 
    cmd.title
LIMIT 100;
