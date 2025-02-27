WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_in_year
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
        AND t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
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
ComplexQuery AS (
    SELECT 
        m.title,
        m.production_year,
        ar.actor_name,
        ar.role,
        cm.company_name,
        cm.company_type,
        mk.keywords,
        COALESCE(mk.keywords, 'No keywords') AS keyword_display
    FROM 
        RankedMovies m
    LEFT JOIN 
        ActorRoles ar ON m.movie_id = ar.movie_id
    LEFT JOIN 
        CompanyMovies cm ON m.movie_id = cm.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.movie_id = mk.movie_id
    WHERE 
        (m.production_year IS NOT NULL OR m.title IS NOT NULL)
        AND (ar.actor_name IS NOT NULL OR cm.company_name IS NOT NULL)
)
SELECT 
    *,
    CASE 
        WHEN rank_in_year = 1 THEN 'Most Recent Movie of the Year'
        ELSE 'Other Movies'
    END AS movie_rank_desc,
    CASE 
        WHEN COUNT(DISTINCT actor_name) OVER (PARTITION BY title) > 3 THEN 'Ensemble Cast'
        ELSE 'Standard Cast'
    END AS cast_type
FROM 
    ComplexQuery
WHERE 
    movie_rank_desc = 'Most Recent Movie of the Year' 
    AND (NOT (company_name IS NULL AND keywords IS NULL))
ORDER BY 
    production_year DESC, title;
