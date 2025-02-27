WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        cd.company_names,
        cd.company_type,
        kd.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanyDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        KeywordDetails kd ON rm.movie_id = kd.movie_id
    WHERE 
        rm.rank = 1 AND rm.production_year >= 2000
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_count,
    COALESCE(fr.company_names, 'No Companies') AS company_names,
    COALESCE(fr.company_type, 'N/A') AS company_type,
    COALESCE(fr.keywords, 'No Keywords') AS keywords
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.actor_count DESC;
