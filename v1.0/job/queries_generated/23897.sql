WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.id) AS rn,
        COALESCE(k.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year IS NOT NULL
),
RankedCast AS (
    SELECT 
        c.id AS cast_id,
        c.movie_id,
        a.name AS actor_name,
        RANK() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_rank
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieInfoSubquery AS (
    SELECT 
        movie_id,
        STRING_AGG(info, '; ') AS info_details
    FROM 
        movie_info
    GROUP BY 
        movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.keyword,
    rc.actor_name,
    rc.role_rank,
    mc.companies,
    mc.company_count,
    mi.info_details
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    RankedCast rc ON r.movie_id = rc.movie_id
LEFT JOIN 
    MovieCompanies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfoSubquery mi ON r.movie_id = mi.movie_id
WHERE 
    (mc.company_count IS NULL OR mc.company_count > 1) 
    AND (r.production_year BETWEEN 1990 AND 2000 OR r.title LIKE '%(2010)%')
ORDER BY 
    r.production_year DESC,
    rc.role_rank,
    r.title;
