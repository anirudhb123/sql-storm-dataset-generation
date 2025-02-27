WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = t.id
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name, 
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    INNER JOIN 
        cast_info c ON c.person_id = ak.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
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
    rm.title,
    rm.production_year,
    rm.cast_count,
    pa.name AS popular_actor,
    mk.keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = rm.movie_id
LEFT JOIN 
    PopularActors pa ON pa.movie_count > 5
WHERE 
    rm.rank <= 10 
    AND (rm.cast_count IS NOT NULL OR mk.keywords IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
