
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rnk
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'feature%' 
            UNION 
            SELECT id FROM kind_type WHERE kind = 'movie'
        )
),
FilteredCast AS (
    SELECT 
        ci.movie_id,
        p.name AS actor_name,
        r.role,
        COALESCE(AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE NULL END), 0) AS participation_rate
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, p.name, r.role
),
MoviesWithCompany AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_type_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fc.actor_name,
        fc.role,
        mc.company_names,
        mc.company_count,
        CASE 
            WHEN mc.company_count > 0 THEN 'Produced'
            WHEN fc.participation_rate > 0.5 THEN 'High Participation' 
            ELSE 'Low Participation'
        END AS status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast fc ON rm.movie_id = fc.movie_id
    LEFT JOIN 
        MoviesWithCompany mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.rnk <= 10 
)
SELECT 
    *
FROM 
    FinalSelection
WHERE 
    production_year BETWEEN 1990 AND 2022
ORDER BY 
    production_year DESC, company_count DESC, actor_name;
