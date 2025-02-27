WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.movie_id
    WHERE 
        a.production_year IS NOT NULL 
    GROUP BY 
        a.id, a.title, a.production_year
), FilteredActors AS (
    SELECT 
        ak.name,
        COUNT(*) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(*) >= 5
), MovieKeywords AS (
    SELECT 
        m.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.title
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    fa.movie_count AS actor_movie_count,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON fa.movie_count = rm.actor_count
LEFT JOIN 
    MovieKeywords mk ON mk.title = rm.title
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, 
    rm.actor_count DESC;
