WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        COUNT(c.person_id) AS cast_count
    FROM 
        aka_title t 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
    HAVING 
        COUNT(c.person_id) > 5  
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        RankedMovies rm
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON rm.movie_id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
),
InfoTypes AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT it.info, '; ') AS additional_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.actors,
    md.company_types,
    it.additional_info
FROM 
    MovieDetails md
LEFT JOIN 
    InfoTypes it ON md.movie_id = it.movie_id
ORDER BY 
    md.production_year DESC, md.title;