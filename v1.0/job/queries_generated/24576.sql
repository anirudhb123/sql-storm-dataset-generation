WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RecursiveCompanyCTE AS (
    SELECT 
        mc.movie_id, 
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci 
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
MoviesWithInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(mi.info) AS info_count,
        STRING_AGG(mi.info, ', ') AS all_info
    FROM 
        title t
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    GROUP BY 
        t.id
    HAVING 
        COUNT(mi.info) > 0
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    COALESCE(actors.actor_count, 0) AS actor_count,
    COALESCE(companies.company_count, 0) AS company_count,
    COALESCE(mi.info_count, 0) AS info_count,
    COALESCE(mi.all_info, 'No Info') AS all_info
FROM 
    RecursiveTitleCTE r
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS actor_count
    FROM 
        RankedCast
    GROUP BY 
        movie_id
) actors ON r.title_id = actors.movie_id
LEFT JOIN (
    SELECT 
        movie_id,
        COUNT(*) AS company_count
    FROM 
        RecursiveCompanyCTE
    GROUP BY 
        movie_id
) companies ON r.title_id = companies.movie_id
LEFT JOIN MoviesWithInfo mi ON r.title_id = mi.movie_id
WHERE 
    r.title_rank <= 5 
    AND (r.production_year > 2000 OR r.title ILIKE '%adventure%')
ORDER BY 
    r.production_year DESC, 
    r.title;
