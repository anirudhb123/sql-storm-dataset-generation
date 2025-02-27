WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) as movie_rank
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
MovieGenres AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS genres
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
PersonRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
TopMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(mg.genres, 'Unknown') AS genres,
        STRING_AGG(DISTINCT pr.role || ' (' || pr.role_count || ')', ', ') AS roles
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieGenres mg ON rm.title = mg.movie_id
    LEFT JOIN 
        PersonRoles pr ON rm.title = pr.movie_id
    WHERE 
        rm.movie_rank <= 10
    GROUP BY 
        rm.title, rm.production_year, mg.genres
)
SELECT 
    tm.title,
    tm.production_year,
    tm.genres,
    tm.roles,
    CASE 
        WHEN tm.roles IS NULL THEN 'No cast information'
        ELSE 'Cast information available'
    END AS cast_info_status
FROM 
    TopMovies tm
ORDER BY 
    tm.production_year DESC, tm.title;
