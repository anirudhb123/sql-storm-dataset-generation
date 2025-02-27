WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) OVER (PARTITION BY t.id) AS cast_count,
        RANK() OVER (ORDER BY t.production_year DESC) AS movie_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year >= 2000
),
MovieGenres AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
DirectorCompanyInfo AS (
    SELECT 
        ci.movie_id,
        cn.name AS company_name,
        cnt.kind AS company_type
    FROM 
        movie_companies ci
    JOIN 
        company_name cn ON ci.company_id = cn.id
    JOIN 
        company_type cnt ON ci.company_type_id = cnt.id
    WHERE 
        ci.note IS NULL
),
TitleDirectorCount AS (
    SELECT 
        m.title_id,
        COUNT(DISTINCT d.person_id) AS director_count
    FROM 
        complete_cast cc
    JOIN 
        aka_title m ON cc.movie_id = m.id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        r.role = 'Director'
    GROUP BY 
        m.title_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mg.genres,
    dci.company_name,
    dci.company_type,
    COALESCE(dc.director_count, 0) AS director_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieGenres mg ON rm.title_id = mg.movie_id
LEFT JOIN 
    DirectorCompanyInfo dci ON rm.title_id = dci.movie_id
LEFT JOIN 
    TitleDirectorCount dc ON rm.title_id = dc.title_id
WHERE 
    (rm.cast_count > 5 OR dci.company_name IS NOT NULL)
    AND (rm.movie_rank <= 10 OR dci.company_type IS NULL)
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC
LIMIT 50;
