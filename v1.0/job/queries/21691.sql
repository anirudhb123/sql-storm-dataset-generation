WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        rm.movie_id,
        rm.title,
        rm.production_year,
        ROW_NUMBER() OVER (PARTITION BY rm.movie_id ORDER BY ak.name) AS actor_order
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        rm.rank <= 10 
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name || ' (' || ct.kind || ')', ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rd.actor_name,
    rd.actor_order,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(cm.companies, 'No Companies') AS companies
FROM 
    RankedMovies rm
JOIN 
    ActorDetails rd ON rm.movie_id = rd.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
WHERE 
    rm.actor_count > 5 
    AND (
        (rm.production_year > 2000 AND mk.keywords IS NOT NULL)
        OR (rm.production_year <= 2000 AND cm.companies IS NOT NULL)
    )
ORDER BY 
    rm.rank, rd.actor_order;