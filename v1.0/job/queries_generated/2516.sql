WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.kind_id ORDER BY a.production_year DESC) AS rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
FilteredActors AS (
    SELECT 
        DISTINCT c.person_id,
        ak.name AS actor_name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        c.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        co.country_code IS NOT NULL
)
SELECT 
    rm.title,
    rm.production_year,
    fa.actor_name,
    fa.movie_count,
    cm.company_name,
    cm.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    FilteredActors fa ON rm.title IN (SELECT 
                                            at.title 
                                        FROM 
                                            aka_title at 
                                        JOIN 
                                            cast_info ci ON at.id = ci.movie_id 
                                        WHERE 
                                            ci.person_id = fa.person_id)
LEFT JOIN 
    CompanyMovies cm ON rm.id IN (SELECT 
                                        mc.movie_id 
                                    FROM 
                                        movie_companies mc 
                                    WHERE 
                                        mc.movie_id = rm.id)
WHERE 
    rm.rank = 1
    AND (cm.company_type = 'Production' OR cm.company_type IS NULL)
ORDER BY 
    rm.production_year DESC, fa.movie_count DESC;
