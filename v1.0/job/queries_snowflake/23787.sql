
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(mci.company_count, 0) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY mci.company_count DESC) AS rank_order
    FROM 
        aka_title t
    LEFT JOIN (
        SELECT 
            movie_id,
            COUNT(DISTINCT mc.company_id) AS company_count
        FROM 
            movie_companies mc
        GROUP BY 
            mc.movie_id
    ) mci ON t.id = mci.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.company_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_order <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    tm.title,
    tm.company_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tm.company_count > 0 THEN 'Has Companies'
        ELSE 'No Companies'
    END AS company_status,
    (SELECT 
         MAX(pi.info) 
     FROM 
         person_info pi 
     WHERE 
         pi.person_id = (SELECT c.person_id 
                         FROM cast_info c 
                         WHERE c.movie_id = tm.movie_id 
                         ORDER BY c.nr_order 
                         LIMIT 1)
    ) AS main_actor_info,
    (SELECT 
         COUNT(DISTINCT c.person_id) 
     FROM 
         cast_info c 
     WHERE 
         c.movie_id = tm.movie_id 
         AND c.person_role_id IS NOT NULL
    ) AS total_roles
FROM 
    TopMovies tm
LEFT JOIN 
    MovieKeywords mk ON tm.movie_id = mk.movie_id
ORDER BY 
    tm.company_count DESC
LIMIT 10;
