WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(cc.person_id) AS actor_count,
        AVG(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mt.id) AS has_note_avg,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC, COUNT(cc.person_id) DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.id
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.actor_count,
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_title = mk.movie_id
    WHERE 
        rm.actor_count > 3
    GROUP BY 
        rm.movie_title, rm.production_year, rm.actor_count
)
SELECT 
    mwk.movie_title,
    mwk.production_year,
    mwk.actor_count,
    COALESCE(mwk.keywords, 'No keywords available') AS keywords,
    ct.kind AS company_type
FROM 
    MoviesWithKeywords mwk
LEFT JOIN 
    movie_companies mc ON mwk.movie_title = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    mwk.rank <= 10
ORDER BY 
    mwk.actor_count DESC, mwk.production_year DESC;
