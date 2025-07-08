
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieCrew AS (
    SELECT 
        ca.movie_id,
        COUNT(DISTINCT ca.person_id) AS total_cast,
        LISTAGG(DISTINCT ca.note, ', ') WITHIN GROUP (ORDER BY ca.note) AS cast_notes
    FROM 
        cast_info ca
    LEFT JOIN 
        RankedMovies rm ON ca.movie_id = rm.movie_id
    GROUP BY 
        ca.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(m.total_cast, 0) AS total_cast,
    COALESCE(m.cast_notes, 'No Cast Information') AS cast_notes,
    COALESCE(cd.company_name, 'Unknown Company') AS company_name,
    cd.company_type
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCrew m ON rm.movie_id = m.movie_id
LEFT JOIN 
    CompanyDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title;
