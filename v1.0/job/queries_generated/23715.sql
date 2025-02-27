WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.id AS cast_id,
        cn.name AS actor_name,
        mt.title AS movie_title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY c.nr_order) AS role_order,
        CASE 
            WHEN c.note IS NULL THEN 'No Notes Available'
            ELSE c.note
        END AS cast_note
    FROM 
        cast_info c
    JOIN 
        aka_name cn ON c.person_id = cn.person_id
    JOIN 
        aka_title mt ON c.movie_id = mt.id
),
TitleKeywords AS (
    SELECT 
        kt.id AS keyword_id,
        kt.keyword,
        mt.title AS movie_title,
        mt.production_year
    FROM 
        movie_keyword mk
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    WHERE 
        kt.keyword IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY cn.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_order,
    cd.cast_note,
    tk.keyword,
    COALESCE(cd.role_order - DENSE_RANK() OVER (PARTITION BY rm.movie_id ORDER BY cd.role_order), 0) AS role_diff,
    cd.cast_id,
    ARRAY_AGG(DISTINCT cd.cast_note) FILTER (WHERE cd.cast_note != 'No Notes Available') AS notes
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_title AND rm.production_year = cd.production_year
LEFT JOIN 
    TitleKeywords tk ON rm.title = tk.movie_title
LEFT JOIN  
    CompanyDetails comp ON rm.movie_id = comp.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.actor_name, cd.role_order, tk.keyword, cd.cast_id
ORDER BY 
    rm.production_year DESC, rm.title, role_diff DESC NULLS LAST;
