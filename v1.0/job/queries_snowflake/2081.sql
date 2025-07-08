
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        t.id, t.title, t.production_year
),
PopularActors AS (
    SELECT 
        ak.name,
        COUNT(DISTINCT rc.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info rc ON ak.person_id = rc.person_id
    GROUP BY 
        ak.name
    HAVING 
        COUNT(DISTINCT rc.movie_id) > 5
),
MoviesWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    pa.movie_count,
    COALESCE(mkw.keywords, 'No keywords') AS movie_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.movie_count = rm.cast_count
LEFT JOIN 
    MoviesWithKeywords mkw ON rm.movie_id = mkw.movie_id
WHERE 
    rm.rank_by_cast <= 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
