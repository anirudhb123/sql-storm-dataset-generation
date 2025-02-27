WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY c.nr_order) AS actor_rank
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        ARRAY_AGG(DISTINCT cn.name) AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.actor_rank,
    mk.keywords,
    mc.company_names
FROM 
    RankedMovies rm
JOIN 
    MovieKeywords mk ON rm.movie_title = mk.movie_id
JOIN 
    MovieCompanies mc ON rm.movie_title = mc.movie_id
WHERE 
    rm.actor_rank <= 3
ORDER BY 
    rm.production_year DESC, rm.movie_title
LIMIT 50;
