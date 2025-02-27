
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_within_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
        AND t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role,
        c.nr_order,
        CASE WHEN c.note IS NULL THEN 'No note' ELSE c.note END AS role_note
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.name IS NOT NULL
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
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
ActorFootprint AS (
    SELECT 
        a.movie_id,
        MIN(a.role) AS primary_role,
        COUNT(DISTINCT a.actor_name) AS actor_count
    FROM 
        ActorRoles a
    JOIN 
        RankedMovies rm ON a.movie_id = rm.movie_id
    GROUP BY 
        a.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ak.keywords,
        ci.company_name,
        ai.primary_role,
        ai.actor_count,
        CASE 
            WHEN rm.rank_within_year <= 10 THEN 'Top 10 of the year'
            ELSE 'Below Top 10'
        END AS rank_status
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords ak ON rm.movie_id = ak.movie_id
    LEFT JOIN 
        CompanyInfo ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        ActorFootprint ai ON rm.movie_id = ai.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    COALESCE(fr.keywords, 'No keywords') AS keywords,
    COALESCE(fr.company_name, 'Independent') AS company_name,
    fr.primary_role,
    fr.actor_count,
    fr.rank_status
FROM 
    FinalResults fr
WHERE 
    fr.rank_status = 'Top 10 of the year'
ORDER BY 
    fr.production_year DESC,
    fr.actor_count DESC
LIMIT 50;
