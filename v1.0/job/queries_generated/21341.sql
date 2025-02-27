WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
HighActorCountMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieKeywords AS (
    SELECT 
        at.title,
        ak.keyword
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ak ON mk.keyword_id = ak.id
    WHERE 
        ak.keyword IS NOT NULL
),
MovieFullDetails AS (
    SELECT 
        at.title,
        ak.name AS actor_name,
        at.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        ci.note AS role_note
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        MovieKeywords mk ON at.title = mk.title
),
FinalResults AS (
    SELECT 
        mfd.title,
        mfd.actor_name,
        mfd.production_year,
        mfd.keyword,
        DENSE_RANK() OVER (PARTITION BY mfd.production_year ORDER BY mfd.actor_name) AS actor_rank
    FROM 
        MovieFullDetails mfd
    WHERE 
        mfd.production_year IS NOT NULL 
        AND mfd.actor_name IS NOT NULL
)
SELECT 
    fr.production_year,
    COUNT(DISTINCT fr.title) AS movie_count,
    MAX(fr.actor_name) AS last_actor_name, -- Obtain the last actor alphabetically for each year
    STRING_AGG(fr.keyword, ', ') AS keywords_list
FROM 
    FinalResults fr
WHERE 
    fr.actor_rank > 1 -- Avoid the top actor for some kind of analysis
GROUP BY 
    fr.production_year
ORDER BY 
    fr.production_year DESC;
