WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        complete_cast cc ON at.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(*) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(*) > 1
),
HighRatedActors AS (
    SELECT 
        ci.person_id,
        a.name,
        COUNT(DISTINCT cc.movie_id) AS movies_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.person_id, a.name
    HAVING 
        COUNT(DISTINCT cc.movie_id) > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    STRING_AGG(kw.keyword, ', ') AS keywords,
    ha.name AS actor_name,
    ha.movies_count 
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularKeywords kw ON rm.title = (SELECT title FROM aka_title WHERE id = kw.movie_id)
LEFT JOIN 
    HighRatedActors ha ON ha.movies_count > 5
WHERE 
    rm.rank <= 10
GROUP BY 
    rm.title, rm.production_year, rm.actor_count, ha.name, ha.movies_count
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
