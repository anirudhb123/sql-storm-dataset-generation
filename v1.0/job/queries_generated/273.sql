WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        t.id
), ActorAwards AS (
    SELECT 
        a.person_id, 
        COUNT(DISTINCT a.id) AS total_awards
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        movie_info mi ON ci.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'award') 
    GROUP BY 
        a.person_id
), MovieKeywords AS (
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
    rm.title,
    rm.production_year,
    COALESCE(aa.total_awards, 0) AS awards_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    COUNT(DISTINCT DISTINCT cc.person_id) FILTER (WHERE cc.status_id IS NULL) AS active_actors
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.title_id = ci.movie_id
LEFT JOIN 
    ActorAwards aa ON ci.person_id = aa.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    complete_cast cc ON cc.movie_id = rm.title_id
WHERE 
    rm.rank = 1
GROUP BY 
    rm.title, rm.production_year, aa.total_awards, mk.keywords
ORDER BY 
    rm.production_year DESC, awards_count DESC
LIMIT 50;
