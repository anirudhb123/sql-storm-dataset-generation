WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),

MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        CASE 
            WHEN rm.rank_by_cast <= 5 THEN 'Top Cast Movies'
            ELSE 'Other Movies'
        END AS movie_category,
        COALESCE(mc.info, 'No additional info') AS company_info,
        COALESCE(k.keyword, 'No keywords') AS movie_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    WHERE 
        rm.production_year IS NOT NULL AND rm.cast_count > 0
),

Actors AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ci.movie_id,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY a.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
)

SELECT 
    md.title,
    md.production_year,
    md.cast_count,
    md.movie_category,
    STRING_AGG(a.actor_name, ', ' ORDER BY a.actor_rank) AS actors,
    md.company_info,
    COUNT(DISTINCT mk.keyword) AS distinct_keywords,
    COUNT(DISTINCT ci.id) AS complete_cast_count
FROM 
    MovieDetails md
LEFT JOIN 
    Actors a ON md.movie_id = a.movie_id
LEFT JOIN 
    complete_cast ci ON md.movie_id = ci.movie_id
WHERE 
    md.movie_category = 'Top Cast Movies'
GROUP BY 
    md.movie_id, md.title, md.production_year, md.cast_count, md.movie_category, md.company_info
HAVING 
    COALESCE(md.company_info, '') != ''
ORDER BY 
    md.production_year DESC, md.cast_count DESC
LIMIT 10;

-- Note: 
-- This query ranks movies by their cast size per production year and categorizes them, 
-- while also aggregating actor names and performing outer joins
-- to bring in additional context such as actors, company information, 
-- and keywords, filtering on movies with substantial casting significance.
