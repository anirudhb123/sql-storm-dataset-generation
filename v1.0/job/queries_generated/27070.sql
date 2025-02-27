WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        ARRAY_AGG(DISTINCT gn.kind) AS genres,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        title m
    JOIN 
        aka_title a ON m.id = a.movie_id
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        (SELECT * FROM kind_type) gn ON m.kind_id = gn.id
    WHERE 
        m.production_year >= 2000
    GROUP BY 
        m.id, m.title, m.production_year
), FilteredRankedMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.genres,
        rm.cast_count,
        rm.actor_names,
        RANK() OVER (PARTITION BY ARRAY_LENGTH(rm.genres, 1) ORDER BY rm.cast_count DESC) AS genre_rank
    FROM 
        RankedMovies rm
)
SELECT 
    frm.movie_id,
    frm.movie_title,
    frm.production_year,
    frm.genres,
    frm.cast_count,
    frm.actor_names,
    frm.genre_rank
FROM 
    FilteredRankedMovies frm
WHERE 
    frm.genre_rank <= 5
ORDER BY 
    frm.production_year DESC, 
    frm.cast_count DESC;
