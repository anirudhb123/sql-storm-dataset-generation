
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_year,
        COUNT(*) OVER (PARTITION BY m.production_year) AS count_per_year 
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT id FROM kind_type WHERE kind NOT LIKE '%short%')
),
ActorMovies AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(*) AS actor_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS noted_roles
    FROM 
        cast_info ci
    INNER JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    INNER JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS company_count
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name comp ON mc.company_id = comp.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, comp.name, ct.kind
),
FinalReport AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.rank_year,
        rm.count_per_year,
        COALESCE(am.actor_count, 0) AS total_actors,
        COALESCE(am.noted_roles, 0) AS noted_roles,
        COALESCE(mk.keywords, 'No keywords') AS keywords,
        COALESCE(ci.company_name, 'Independent') AS company_name,
        COALESCE(ci.company_type, 'Independent') AS company_type,
        COALESCE(ci.company_count, 0) AS company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON rm.movie_id = am.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    WHERE 
        rm.production_year IS NOT NULL 
        AND (rm.count_per_year > 5 OR rm.rank_year <= 3)
        AND (
            ci.company_count IS NULL 
            OR ci.company_count > 1 
            OR ci.company_type LIKE 'Studio%'
        )
    ORDER BY 
        rm.production_year DESC, rm.rank_year ASC
)

SELECT 
    title, 
    production_year,
    total_actors,
    noted_roles,
    keywords,
    company_name 
FROM 
    FinalReport
WHERE 
    production_year > 2000
    AND total_actors > 1
    AND (
        EXISTS (SELECT 1 FROM complete_cast cc WHERE cc.movie_id = FinalReport.movie_id AND cc.status_id IS NOT NULL)
        OR keywords != 'No keywords'
    )
ORDER BY 
    total_actors DESC, production_year;
