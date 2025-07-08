
WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON ci.movie_id = at.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON k.id = mk.keyword_id
    GROUP BY 
        mk.movie_id
),
DirectorAndProducers AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind IN ('Director', 'Producer'))
    GROUP BY 
        mc.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    COALESCE(dp.company_names, 'No Companies') AS director_producer_names
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON mk.movie_id = (SELECT movie_id FROM aka_title WHERE title = rm.title ORDER BY production_year DESC LIMIT 1)
LEFT JOIN 
    DirectorAndProducers dp ON dp.movie_id = (SELECT movie_id FROM aka_title WHERE title = rm.title ORDER BY production_year DESC LIMIT 1)
WHERE 
    rm.year_rank <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
