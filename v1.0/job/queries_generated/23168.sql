WITH RankedMovies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COALESCE(k.keyword, 'Unknown') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS year_rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IN (SELECT id FROM role_type WHERE role = 'Actor')
    GROUP BY 
        ci.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mci.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NULL
    GROUP BY 
        mc.movie_id
),
FinalOutput AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.keyword,
        ac.actor_count,
        mcd.company_count,
        mcd.company_names,
        CASE 
            WHEN ac.actor_count IS NULL THEN 'No Actors'
            WHEN ac.actor_count >= 10 THEN 'Star-studded'
            ELSE 'Moderate Cast'
        END AS cast_description
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_title = (SELECT title FROM aka_title WHERE id = ac.movie_id)
    LEFT JOIN 
        MovieCompanyDetails mcd ON rm.movie_title = (SELECT title FROM aka_title WHERE id = mcd.movie_id)
)
SELECT 
    movie_title,
    production_year,
    keyword,
    COALESCE(actor_count, 0) AS actor_count,
    COALESCE(company_count, 0) AS company_count,
    company_names,
    cast_description
FROM 
    FinalOutput
WHERE 
    production_year > 2000 
    AND (keyword IS NOT NULL OR company_count > 0)
ORDER BY 
    production_year DESC,
    movie_title;
