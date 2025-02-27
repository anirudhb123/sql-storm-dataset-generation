
WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_in_year,
        t.id -- assuming t.id is the primary key for aka_title
    FROM 
        aka_title t
    WHERE 
        EXTRACT(YEAR FROM DATE '2024-10-01') - t.production_year <= 10
),
CastSummary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT a.person_id) AS total_cast,
        COUNT(DISTINCT CASE WHEN r.role IS NOT NULL THEN a.person_id END) AS roles_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        COUNT(DISTINCT co.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    DISTINCT rm.title,
    rm.production_year,
    cs.total_cast,
    cs.roles_count,
    COALESCE(mc.company_names, 'No companies') AS company_names,
    CASE 
        WHEN ds.popularity IS NULL THEN 'Not Popular'
        WHEN ds.popularity > 7 THEN 'Highly Popular'
        ELSE 'Moderately Popular'
    END AS popularity_description
FROM 
    RankedMovies rm
LEFT JOIN 
    CastSummary cs ON rm.id = cs.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.id = mc.movie_id
LEFT JOIN (
    SELECT 
        m.id AS movie_id,
        AVG(CAST(mi.info AS FLOAT)) AS popularity
    FROM 
        title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        m.id
) ds ON rm.id = ds.movie_id
WHERE 
    rm.rank_in_year <= 5
ORDER BY 
    rm.production_year DESC, rm.title;
