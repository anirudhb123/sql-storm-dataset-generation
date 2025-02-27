WITH RankedMovies AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rn 
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id
),
CompanyCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.actor_name,
    rm.movie_title,
    rm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(cc.company_count, 0) AS num_companies
FROM 
    RankedMovies rm
LEFT JOIN 
    MoviesWithKeywords mk ON rm.rn = 1 AND rm.movie_title = mk.movie_id
LEFT JOIN 
    CompanyCount cc ON rm.rn = 1 AND rm.movie_title = cc.movie_id
WHERE 
    rm.rn = 1
ORDER BY 
    rm.production_year DESC, rm.actor_name;
