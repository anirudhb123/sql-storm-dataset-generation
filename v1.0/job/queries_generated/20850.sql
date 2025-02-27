WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
HighActorMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_actors
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 5
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    ham.title,
    ham.production_year,
    ham.total_actors,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_info mi 
     WHERE 
        mi.movie_id = ham.movie_id 
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Budget')
    ) AS budget_info_count,
    COUNT(DISTINCT cn.id) FILTER (WHERE cn.country_code IS NOT NULL) AS countries_count
FROM 
    HighActorMovies ham
LEFT JOIN 
    movie_companies mc ON ham.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    MovieKeywords mk ON ham.movie_id = mk.movie_id
WHERE 
    EXISTS (
        SELECT 1 
        FROM complete_cast cc 
        WHERE cc.movie_id = ham.movie_id 
          AND cc.status_id IS NOT NULL
    )
GROUP BY 
    ham.movie_id, ham.title, ham.production_year, ham.total_actors, mk.keywords
ORDER BY 
    ham.total_actors DESC, ham.production_year ASC
LIMIT 10;
