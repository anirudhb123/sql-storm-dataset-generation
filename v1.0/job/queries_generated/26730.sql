WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        rt.role,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(CONCAT(a.name, ' as ', rt.role), ', ') AS cast_members
    FROM 
        title m
    JOIN 
        cast_info ci ON m.id = ci.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        m.production_year >= 2000
        AND rt.role IN ('Director', 'Actor', 'Producer')
    GROUP BY 
        m.id, m.title, m.production_year, rt.role
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.role,
        rm.cast_count,
        rm.cast_members,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Budget') THEN mi.info::numeric END), 0) AS budget,
        COALESCE(SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN mi.info::numeric END), 0) AS box_office
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.role, rm.cast_count, rm.cast_members
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.role,
    md.cast_count,
    md.cast_members,
    md.budget,
    md.box_office,
    CASE 
        WHEN md.box_office - md.budget > 0 THEN 'Profitable'
        WHEN md.box_office - md.budget < 0 THEN 'Loss'
        ELSE 'Break Even'
    END AS financial_status
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, md.box_office DESC
LIMIT 10;
