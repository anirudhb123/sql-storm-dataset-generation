WITH RankedMovies AS (
    SELECT 
        mt.title, 
        mt.production_year, 
        COUNT(DISTINCT ci.person_id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    GROUP BY 
        mt.title, mt.production_year
),
MoviesWithKeywords AS (
    SELECT 
        mt.title,
        mt.production_year,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.title, mt.production_year
),
EligibleMovies AS (
    SELECT 
        rm.title, 
        rm.production_year, 
        mwk.keywords,
        COALESCE(mwk.keywords, 'No Keywords') AS keywords_display
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MoviesWithKeywords mwk ON rm.title = mwk.title AND rm.production_year = mwk.production_year
    WHERE 
        rm.rank <= 5
    ORDER BY 
        rm.production_year DESC, 
        rm.num_actors DESC
)
SELECT 
    em.title, 
    em.production_year, 
    em.keywords_display,
    CASE 
        WHEN em.keywords IS NULL THEN 'No Keywords Available'
        ELSE em.keywords
    END AS formatted_keywords,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id IN (SELECT id FROM aka_title WHERE title = em.title)) AS total_cast
FROM 
    EligibleMovies em
WHERE 
    em.production_year IS NOT NULL AND em.production_year > 2000
ORDER BY 
    em.production_year DESC, 
    em.title;
