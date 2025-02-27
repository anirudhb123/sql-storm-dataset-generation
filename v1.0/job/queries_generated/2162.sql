WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS special_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'plot')
    LEFT JOIN 
        char_name ch ON c.person_id = ch.imdb_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.special_cast_count,
        RANK() OVER (ORDER BY md.cast_count DESC) AS rank_by_cast
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.special_cast_count,
    rt.role AS role_type
FROM 
    RankedMovies rm
LEFT JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    rm.cast_count > 5 OR (rm.special_cast_count > 0 AND rm.rank_by_cast <= 10)
ORDER BY 
    rm.rank_by_cast, rm.title;
