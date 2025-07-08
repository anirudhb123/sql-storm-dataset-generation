WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
NotableMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rd.company_name,
        rd.company_type
    FROM 
        RankedMovies rm
    INNER JOIN 
        CompanyDetails rd ON rm.movie_id = rd.movie_id
    WHERE 
        rm.rank_by_cast <= 5
)
SELECT 
    nm.title,
    nm.company_name,
    nm.company_type,
    COALESCE(mi.info, 'No Additional Info') AS additional_info
FROM 
    NotableMovies nm
LEFT JOIN 
    movie_info mi ON nm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
WHERE 
    nm.company_type IS NOT NULL
ORDER BY 
    nm.title;
