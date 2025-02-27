WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredActors AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        cm.name AS company_name
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cm ON mc.company_id = cm.id
    WHERE 
        ak.name IS NOT NULL
        AND cm.country_code IS NOT NULL
),

MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ra.actor_name,
        COALESCE(mkc.keyword_count, 0) AS keyword_count,
        ra.company_name,
        rm.actor_rank
    FROM 
        RankedMovies rm
    JOIN 
        FilteredActors ra ON rm.movie_id = ra.person_id
    LEFT JOIN 
        MovieKeywordCounts mkc ON rm.movie_id = mkc.movie_id
    WHERE 
        rm.actor_rank = 1
)

SELECT 
    fr.title,
    fr.production_year,
    STRING_AGG(DISTINCT fr.actor_name, ', ') AS actors,
    fr.keyword_count,
    fr.company_name
FROM 
    FinalResults fr
WHERE 
    fr.keyword_count > (SELECT AVG(keyword_count) FROM MovieKeywordCounts)
GROUP BY 
    fr.title, fr.production_year, fr.company_name
HAVING 
    COUNT(fr.actor_name) > 3
ORDER BY 
    fr.production_year DESC, fr.keyword_count DESC;
