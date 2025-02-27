
WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY ak.name) AS actor_rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year IS NOT NULL
        AND ak.name IS NOT NULL
),
ActorWordCounts AS (
    SELECT 
        movie_title,
        production_year,
        SUM(LENGTH(actor_name) - LENGTH(REPLACE(actor_name, ' ', '')) + 1) AS actor_word_count
    FROM 
        RankedMovies
    GROUP BY 
        movie_title, production_year
),
MoviesWithKeywords AS (
    SELECT 
        at.title,
        at.production_year,
        kw.keyword,
        COALESCE(mii.info, 'No additional info') AS additional_info,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        movie_info_idx mii ON mii.movie_id = at.id AND mii.info_type_id = (
            SELECT id FROM info_type WHERE info = 'Rating'
        )
    GROUP BY 
        at.title, at.production_year, kw.keyword, mii.info
),
FinalResults AS (
    SELECT 
        mwk.title AS movie_title,
        mwk.production_year,
        mwk.keyword,
        mwk.additional_info,
        awc.actor_word_count,
        mwk.keyword_count,
        CASE 
            WHEN mwk.keyword_count > 0 THEN 
                'Has Keywords'
            ELSE 
                'No Keywords'
        END AS keyword_status
    FROM 
        MoviesWithKeywords mwk
    LEFT JOIN 
        ActorWordCounts awc ON mwk.title = awc.movie_title 
          AND mwk.production_year = awc.production_year
    WHERE 
        mwk.production_year >= 2000
        AND mwk.additional_info IS NOT NULL
)
SELECT 
    movie_title,
    production_year,
    keyword,
    additional_info,
    actor_word_count,
    keyword_count,
    keyword_status
FROM 
    FinalResults
WHERE 
    (actor_word_count IS NULL OR actor_word_count > 3) 
    AND (keyword_status = 'Has Keywords' OR production_year IN (SELECT DISTINCT production_year FROM MoviesWithKeywords))
ORDER BY 
    production_year DESC, 
    actor_word_count DESC;
