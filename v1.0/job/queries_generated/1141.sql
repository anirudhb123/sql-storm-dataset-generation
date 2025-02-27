WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
), 
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year, 
        actor_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
), 
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS companies,
        GROUP_CONCAT(DISTINCT ct.kind ORDER BY ct.kind) AS company_types
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name co ON mc.company_id = co.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    tm.movie_id, 
    tm.title, 
    tm.production_year, 
    tm.actor_count,
    cd.companies,
    cd.company_types,
    CASE 
        WHEN tm.production_year < 2000 THEN 'Classic'
        WHEN tm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era,
    COALESCE(NULLIF(ROUND(AVG(CASE WHEN m_info.info_type_id = 1 THEN LENGTH(m_info.info)::float END), 2), 0), 'N/A') AS avg_info_length
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info m_info ON tm.movie_id = m_info.movie_id
LEFT JOIN 
    CompanyDetails cd ON tm.movie_id = cd.movie_id
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.actor_count, cd.companies, cd.company_types
ORDER BY 
    tm.actor_count DESC, tm.production_year ASC;
