WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, ct.kind
),
MovieDetails AS (
    SELECT 
        r.title,
        r.production_year,
        COALESCE(ci.company_names, 'No Companies') AS company_names,
        COALESCE(ci.company_type, 'Unknown') AS company_type,
        r.cast_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        CompanyInfo ci ON r.title = ci.movie_id
    WHERE 
        r.cast_count > 5
)

SELECT 
    m.title,
    m.production_year,
    m.company_names,
    m.company_type,
    m.cast_count,
    CASE 
        WHEN m.cast_count IS NULL THEN 'Data Missing'
        WHEN m.cast_count > 10 THEN 'Popular'
        ELSE 'Niche'
    END AS popularity_category
FROM 
    MovieDetails m
WHERE 
    m.rank_per_year <= 5
ORDER BY 
    m.production_year DESC, m.cast_count DESC;

WITH UnusedRoles AS (
    SELECT 
        DISTINCT r.role 
    FROM 
        role_type r
    LEFT JOIN 
        cast_info c ON r.id = c.role_id
    WHERE 
        c.id IS NULL
),
MissingActors AS (
    SELECT 
        COUNT(*) AS missing_actors_count,
        r.role 
    FROM 
        UnusedRoles r
    LEFT JOIN 
        person_info pi ON r.role = pi.info
    WHERE 
        pi.info IS NULL
    GROUP BY 
        r.role
)

SELECT 
    role,
    missing_actors_count,
    CASE 
        WHEN missing_actors_count > 5 THEN 'High Demand'
        ELSE 'Low Demand'
    END AS role_demand
FROM 
    MissingActors
ORDER BY 
    missing_actors_count DESC;
