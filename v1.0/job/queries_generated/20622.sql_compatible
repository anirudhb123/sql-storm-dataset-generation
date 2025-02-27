
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.id) AS year_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS unique_actors,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
CompaniesInfo AS (
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
AggregatedInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(cir.unique_actors, 0) AS unique_actors,
        COALESCE(ci.company_name, 'Unknown') AS company_name,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        m.production_year,
        RANK() OVER (ORDER BY m.production_year DESC, cir.unique_actors DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        CastInfoWithRoles cir ON m.id = cir.movie_id
    LEFT JOIN 
        CompaniesInfo ci ON m.id = ci.movie_id
    LEFT JOIN 
        MovieKeywords mk ON m.id = mk.movie_id
)
SELECT 
    ag.movie_id,
    ag.title,
    ag.unique_actors,
    ag.company_name,
    ag.keywords,
    ag.production_year,
    ag.rank,
    CASE 
        WHEN ag.unique_actors IS NULL THEN 'No Cast'
        WHEN ag.unique_actors = 0 THEN 'No Actors'
        ELSE CONCAT('Featuring ', ag.unique_actors, ' cast members')
    END AS cast_info
FROM 
    AggregatedInfo ag 
WHERE 
    (EXTRACT(YEAR FROM DATE '2024-10-01') - ag.production_year) <= 10
    AND ag.rank <= 100
ORDER BY 
    ag.production_year DESC,
    ag.unique_actors DESC
LIMIT 50;
