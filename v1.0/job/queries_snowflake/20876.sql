
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM
        aka_title t
    LEFT JOIN
        cast_info c ON t.id = c.movie_id
    WHERE
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count
    FROM
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    INNER JOIN 
        company_name c ON mc.company_id = c.id
    INNER JOIN 
        company_type ct ON mc.company_type_id = ct.id
),

DetailedMovies AS (
    SELECT 
        f.movie_id,
        f.title,
        f.production_year,
        f.cast_count,
        cd.company_name,
        cd.company_type,
        ROW_NUMBER() OVER (PARTITION BY f.movie_id ORDER BY cd.company_name) AS company_rank
    FROM 
        FilteredMovies f
    LEFT JOIN 
        CompanyDetails cd ON f.movie_id = cd.movie_id
)

SELECT 
    dm.title AS movie_title,
    dm.production_year,
    dm.cast_count,
    dm.company_name,
    dm.company_type,
    CASE 
        WHEN dm.company_rank IS NULL THEN 'No company details available'
        ELSE dm.company_name || ' (' || dm.company_type || ')'
    END AS company_info,
    COALESCE(SUM(CASE WHEN mi.info IS NOT NULL AND LENGTH(mi.info) > 20 THEN 1 ELSE 0 END), 0) AS long_info_count,
    CASE 
        WHEN COUNT(DISTINCT ki.keyword) > 0 THEN LISTAGG(ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword)
        ELSE 'No keywords available' 
    END AS movie_keywords
FROM 
    DetailedMovies dm
LEFT JOIN 
    movie_info mi ON dm.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON dm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    dm.movie_id, dm.title, dm.production_year, dm.cast_count, dm.company_name, dm.company_type, dm.company_rank
HAVING 
    dm.cast_count > 0
ORDER BY 
    dm.production_year DESC, dm.cast_count DESC;
