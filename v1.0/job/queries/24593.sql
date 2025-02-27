WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
), 

CompanyAssociation AS (
    SELECT 
        mc.movie_id,
        COALESCE(CN.name, 'Unknown Company') AS company_name,
        CT.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY CN.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name CN ON mc.company_id = CN.id
    JOIN 
        company_type CT ON mc.company_type_id = CT.id
), 

MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS combined_info 
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
), 

HighestRanked AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.actor_count,
        c.company_name,
        c.company_type,
        m.combined_info
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyAssociation c ON r.movie_id = c.movie_id AND c.company_rank = 1
    LEFT JOIN 
        MovieInfo m ON r.movie_id = m.movie_id
    WHERE 
        r.rank <= 10
)

SELECT 
    hr.movie_id,
    hr.title,
    hr.production_year,
    hr.actor_count,
    hr.company_name,
    hr.company_type,
    hr.combined_info,
    CASE 
        WHEN hr.actor_count IS NULL THEN 'No Actors'
        ELSE 'Has Actors'
    END AS actor_status,
    CASE 
        WHEN hr.combined_info IS NULL THEN 'No Additional Info'
        ELSE hr.combined_info
    END AS filtered_info
FROM 
    HighestRanked hr
ORDER BY 
    hr.production_year DESC, hr.actor_count DESC;