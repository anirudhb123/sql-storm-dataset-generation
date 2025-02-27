WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT m.id) DESC) AS movie_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_title at ON t.id = at.movie_id
    LEFT JOIN 
        aka_name an ON at.id = an.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        name n ON ci.person_id = n.id
    GROUP BY 
        t.id
), MovieWithPopularity AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        COALESCE(SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END), 0) AS cast_count,
        COALESCE(SUM(CASE WHEN mk.id IS NOT NULL THEN 1 ELSE 0 END), 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        cast_info ci ON rm.title_id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.title_id = mk.movie_id
    WHERE 
        rm.movie_rank <= 5  -- top 5 movies per year
    GROUP BY 
        rm.title_id
), FinalResult AS (
    SELECT 
        mw.title,
        mw.production_year,
        mw.cast_count,
        mw.keyword_count,
        CASE 
            WHEN mw.cast_count IS NULL THEN 'No Cast'
            WHEN mw.keyword_count > 3 THEN 'Popular Movie'
            ELSE 'Unknown Popularity'
        END AS popularity_category
    FROM 
        MovieWithPopularity mw
    WHERE 
        mw.cast_count > 0 OR mw.keyword_count > 0
)
SELECT 
    title,
    production_year,
    cast_count,
    keyword_count,
    popularity_category
FROM 
    FinalResult
WHERE 
    (cast_count > 5 AND keyword_count < 3) OR (keyword_count > 5)
ORDER BY 
    production_year DESC, cast_count DESC;
