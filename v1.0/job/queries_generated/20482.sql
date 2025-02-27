WITH RankedMovies AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS year_rank,
        COUNT(*) OVER (PARTITION BY ak.person_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL 
        AND at.production_year IS NOT NULL
),
SelectedMovies AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        movie_count
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
MoviesWithKeywords AS (
    SELECT 
        sm.actor_name,
        sm.movie_title,
        sm.production_year,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        movie_keyword mk ON sm.movie_title = mk.movie_id  -- assume there is a way to correlate titles to keywords
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        sm.actor_name, sm.movie_title, sm.production_year
),
MoviesWithInfo AS (
    SELECT 
        mwk.actor_name,
        mwk.movie_title,
        mwk.production_year,
        mwk.keywords,
        mi.info AS info_details
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        movie_info mi ON mwk.movie_title = mi.movie_id  -- assume there's a correlation with a title id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')  -- getting specific info type
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keywords,
    COALESCE(info_details, 'No info available') AS info_summary,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = (SELECT id FROM aka_title WHERE title = mw.movie_title LIMIT 1)) AS total_complete_cast
FROM 
    MoviesWithInfo mw
ORDER BY 
    production_year DESC, actor_name;

-- Adding a bizarre twist: creating a requirement for a NULL value or an empty keyword set
HAVING 
    (ARRAY_LENGTH(NULLIF(STRING_TO_ARRAY(mw.keywords, ', '), '{}'), 1) IS NULL 
     OR mw.keywords IS NULL)

