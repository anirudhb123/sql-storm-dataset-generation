WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year IS NOT NULL
),

MovieCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(DISTINCT CONCAT(a.name, ' as ', r.role) ORDER BY c.nr_order) AS cast_list
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),

MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT CONCAT(i.info, ': ', mi.info) ORDER BY i.info) AS movie_info
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keyword,
    mc.cast_list,
    mi.movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCast mc ON rm.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.keyword_rank <= 3
ORDER BY 
    rm.production_year DESC, 
    rm.keyword;
