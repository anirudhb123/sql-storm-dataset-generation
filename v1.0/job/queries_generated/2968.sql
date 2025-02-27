WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieCount AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
),
MovieStaffDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    amc.movie_count,
    COALESCE(mcd.company_names, 'No Companies') AS production_companies,
    COALESCE(mcd.keywords, 'No Keywords') AS movie_keywords,
    CASE 
        WHEN rm.title_rank > 5 THEN 'Low Rank'
        ELSE 'High Rank'
    END AS title_rank_status
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorMovieCount amc ON rm.movie_id = amc.movie_id
LEFT JOIN 
    MovieStaffDetails mcd ON rm.movie_id = mcd.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2023) 
    OR (rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
