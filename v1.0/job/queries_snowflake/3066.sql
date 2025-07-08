
WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_in_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
PopularActors AS (
    SELECT 
        ci.person_id,
        ak.name AS actor_name,
        COUNT(*) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.person_id, ak.name
    HAVING 
        COUNT(*) > 10
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
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
    pa.actor_name,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    rm.rank_in_year
FROM 
    RankedMovies rm
LEFT JOIN 
    complete_cast cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    PopularActors pa ON cc.subject_id = pa.person_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.rank_in_year <= 5
ORDER BY 
    rm.production_year DESC, rm.rank_in_year ASC;
