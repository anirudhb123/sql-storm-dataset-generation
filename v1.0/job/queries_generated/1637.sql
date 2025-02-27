WITH RankedMovies AS (
    SELECT 
        mt.title,
        mt.production_year,
        count(k.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year DESC) AS rank
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank = 1
),
MovieCast AS (
    SELECT 
        DISTINCT ct.role AS cast_role, 
        ca.person_id, 
        at.title 
    FROM 
        cast_info ca
    JOIN 
        role_type ct ON ca.role_id = ct.id
    JOIN 
        aka_title at ON ca.movie_id = at.id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS note_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
)

SELECT 
    tm.title,
    tm.production_year,
    COALESCE(cast_info.cast_role, 'Unknown') AS cast_role,
    ci.company_name,
    ci.company_type,
    ci.note_count,
    COALESCE(NULLIF(LOWER(tm.title), 'unknown title'), 'Title Not Available') AS processed_title
FROM 
    TopMovies tm
LEFT JOIN 
    MovieCast cast_info ON tm.title = cast_info.title
LEFT JOIN 
    CompanyInfo ci ON tm.production_year = ci.movie_id
WHERE 
    tm.production_year >= 2000
ORDER BY 
    tm.production_year DESC, 
    tm.title;
