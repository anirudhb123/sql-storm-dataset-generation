WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank,
        COUNT(mk.keyword_id) FILTER (WHERE mk.keyword_id IS NOT NULL) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
CastDetails AS (
    SELECT
        DISTINCT c.person_id,
        a.name AS actor_name,
        m.title AS movie_title,
        m.production_year,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS cast_rank
    FROM
        cast_info c
    JOIN
        aka_name a ON c.person_id = a.person_id
    JOIN 
        aka_title m ON c.movie_id = m.id
    WHERE
        a.name IS NOT NULL AND a.name <> '' 
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, c.name, ct.kind
)
SELECT 
    rm.title,
    rm.production_year,
    COUNT(DISTINCT cd.actor_name) AS total_actors,
    COALESCE(SUM(cd.cast_rank), 0) AS total_cast_rank,
    COALESCE(COUNT(DISTINCT comp.company_name), 0) AS total_companies,
    COALESCE(SUM(comp.company_count), 0) AS company_count,
    COALESCE(SUM(rm.keyword_count), 0) AS total_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyDetails comp ON rm.movie_id = comp.movie_id
WHERE 
    rm.year_rank = 1
    AND (rm.production_year IS NOT NULL OR rm.production_year IS NOT NULL) -- bizarre condition for potential NULL filtering
GROUP BY 
    rm.title, 
    rm.production_year
HAVING 
    COUNT(DISTINCT cd.actor_name) > 5    -- More than 5 different actors
    OR SUM(comp.company_count) > 3        -- OR more than 3 companies involved
ORDER BY 
    rm.production_year DESC, 
    total_actors DESC;
