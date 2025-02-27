WITH RankedTitles AS (
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
CastDetails AS (
    SELECT 
        ci.movie_id,
        ai.name AS actor_name,
        ai.surname_pcode,
        rt.role AS role_name,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast,
        COALESCE(cn.name, 'Unknown Company') AS production_company
    FROM 
        cast_info ci
    JOIN 
        aka_name ai ON ci.person_id = ai.person_id
    LEFT JOIN 
        movie_companies mc ON ci.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieInfoWithKeywords AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        k.keyword AS movie_keyword,
        COALESCE(mi.info, 'No additional info') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
),
FilteredMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        ci.actor_name,
        ci.production_company,
        ci.total_cast,
        mi.movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY rt.production_year ORDER BY rt.title) AS year_rank
    FROM 
        RankedTitles rt
    JOIN 
        CastDetails ci ON rt.title_id = ci.movie_id
    LEFT JOIN 
        MovieInfoWithKeywords mi ON rt.title_id = mi.movie_id
    WHERE 
        (ci.total_cast > 5 OR ci.production_company <> 'Unknown Company') -- Filter for larger casts or known companies
        AND (rt.production_year > 2000 OR mi.movie_keyword IS NOT NULL) -- Filter after 2000 or has keywords
)
SELECT 
    f.title,
    f.actor_name,
    f.production_company,
    f.movie_keyword,
    f.year_rank
FROM 
    FilteredMovies f
WHERE 
    f.year_rank BETWEEN 1 AND 3 -- Get top 3 titles per year
ORDER BY 
    f.title, f.production_company NULLS LAST; -- Order by title and place NULL production companies last

This query uses Common Table Expressions (CTEs) to structure the data retrieval, incorporates window functions for ranking, outer joins for including information related to cast details and company names, and applies complicated filtering and ordering criteria. It also demonstrates handling of NULL values and various predicates, showcasing SQL's capabilities.
