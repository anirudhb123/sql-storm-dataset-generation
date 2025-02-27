WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        ak.name AS actor_name, 
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title AS t
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    JOIN 
        aka_name AS ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_companies AS mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, ak.name
),
FilteredMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        rm.actor_name, 
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn = 1 AND rm.company_count > 5
)
SELECT 
    fm.title, 
    fm.production_year, 
    fm.actor_name, 
    fm.company_count
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.title;
