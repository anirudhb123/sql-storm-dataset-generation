WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieCast AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT p.name, ', ') AS cast_names
    FROM 
        complete_cast m
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    JOIN 
        aka_name p ON c.person_id = p.person_id
    GROUP BY 
        m.movie_id
),
CompanyStats AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(cs.movie_count, 0) AS production_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mc ON rm.movie_id = mc.movie_id
    LEFT JOIN 
        CompanyStats cs ON rm.movie_id = cs.movie_id
    WHERE 
        rm.rank <= 10
)

SELECT 
    sm.title,
    sm.production_year,
    CASE 
        WHEN sm.total_cast > 5 THEN 'Many Cast'
        WHEN sm.total_cast = 0 THEN 'No Cast'
        ELSE 'Few Cast'
    END AS cast_description,
    sm.production_count,
    (SELECT AVG(total_cast) FROM MovieCast) AS avg_cast_count
FROM 
    SelectedMovies sm
ORDER BY 
    sm.production_year DESC, sm.title;
