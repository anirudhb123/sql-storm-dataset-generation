
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        MAX(CASE WHEN rt.role = 'actor' THEN 1 ELSE 0 END) AS is_actor,
        MAX(CASE WHEN rt.role = 'director' THEN 1 ELSE 0 END) AS is_director
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        LISTAGG(DISTINCT c.name, ', ') WITHIN GROUP (ORDER BY c.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.movie_count, 0) AS actor_movie_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(DISTINCT ci.person_id) 
     FROM cast_info ci 
     WHERE ci.movie_id = rm.movie_id AND ci.person_role_id IS NOT NULL 
     ) AS distinct_cast_count,
    (SELECT AVG(production_year) 
     FROM aka_title 
     WHERE production_year > 2000
     ) AS average_recent_year
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoleCounts ac ON rm.movie_id = ac.person_id
LEFT JOIN 
    CompanyMovies cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    MoviesWithKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.year_rank = 1
ORDER BY 
    rm.production_year DESC, rm.title ASC;
