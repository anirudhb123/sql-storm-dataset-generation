
WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        COUNT(ci.person_id) AS cast_count,
        a.id
    FROM 
        aka_title AS a
    LEFT JOIN 
        complete_cast AS cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.id, a.title, a.production_year
), MovieInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT ki.keyword, ', ') AS keywords,
        MAX(mi.info) FILTER (WHERE it.info = 'plot') AS plot_info
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS ki ON mk.keyword_id = ki.id
    JOIN 
        movie_info AS mi ON mk.movie_id = mi.movie_id
    JOIN 
        info_type AS it ON mi.info_type_id = it.id
    GROUP BY 
        mk.movie_id
), CompanyDetails AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS c ON mc.company_id = c.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
), FinalResult AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        mi.keywords,
        mi.plot_info,
        COALESCE(cd.company_name, 'Unknown') AS company_name,
        COALESCE(cd.company_type, 'Unknown') AS company_type
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        MovieInfo AS mi ON rm.id = mi.movie_id
    LEFT JOIN 
        CompanyDetails AS cd ON rm.id = cd.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    keywords,
    plot_info,
    company_name,
    company_type
FROM 
    FinalResult
WHERE 
    production_year BETWEEN 1990 AND 2020
ORDER BY 
    cast_count DESC, production_year ASC
LIMIT 100;
