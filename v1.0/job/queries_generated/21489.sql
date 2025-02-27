WITH RecursiveCte AS (
    SELECT 
        ct.title,
        ct.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        aka_title AS ct
    JOIN 
        cast_info AS ci ON ct.id = ci.movie_id
    WHERE 
        ct.production_year IS NOT NULL
    GROUP BY 
        ct.title, ct.production_year
    HAVING 
        COUNT(DISTINCT ci.person_id) >= 5
),
FilteredMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER(PARTITION BY m.production_year ORDER BY m.production_year DESC) AS rn
    FROM 
        title AS m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature')
),
TopMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year
    FROM 
        FilteredMovies AS fm
    WHERE 
        fm.rn <= 10
),
MovieCompanies AS (
    SELECT DISTINCT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
)
SELECT 
    tm.title AS movie_title,
    tm.production_year,
    mca.company_name,
    mca.company_type,
    rc.actor_count,
    COALESCE(mi.info, 'No info available') AS movie_info,
    CASE 
        WHEN rc.actor_count > 10 THEN 'Star-studded'
        WHEN rc.actor_count BETWEEN 5 AND 10 THEN 'Moderately casted'
        ELSE 'Under-casted' 
    END AS casting_quality
FROM 
    TopMovies AS tm
LEFT JOIN 
    MovieCompanies AS mca ON tm.movie_id = mca.movie_id
LEFT JOIN 
    RecursiveCte AS rc ON tm.title = rc.title AND tm.production_year = rc.production_year
LEFT JOIN 
    movie_info AS mi ON tm.movie_id = mi.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info IN ('Synopsis', 'Awards'))
WHERE 
    mca.company_type NOT IN (SELECT kind FROM company_type WHERE kind LIKE '%fiction%')
ORDER BY 
    tm.production_year DESC, rc.actor_count DESC, mca.company_name;
