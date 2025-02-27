WITH RankedMovies AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
        LEFT JOIN cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
        JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.name) AS company_count
    FROM 
        movie_companies mc
        JOIN company_name m ON mc.company_id = m.id
    GROUP BY 
        mc.movie_id
)
SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    mk.keywords,
    COALESCE(cc.company_count, 0) AS company_count,
    CASE
        WHEN rm.production_year IS NOT NULL THEN 
            CASE 
                WHEN rm.rank <= 3 THEN 'Top Film'
                ELSE 'Regular Film' 
            END
        ELSE 'Unknown Year'
    END AS film_category
FROM 
    RankedMovies rm
    LEFT JOIN MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN CompanyCounts cc ON rm.movie_id = cc.movie_id
WHERE 
    rm.rank <= 5 OR rm.cast_count > 10
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
