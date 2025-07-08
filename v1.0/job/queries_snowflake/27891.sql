
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.production_year DESC) AS year_rank
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
),
MovieCastInfo AS (
    SELECT 
        mc.movie_id,
        c.name AS actor_name,
        r.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS actor_rank
    FROM 
        complete_cast mc
    JOIN 
        cast_info ci ON mc.subject_id = ci.person_id
    JOIN 
        name c ON ci.person_id = c.id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        ci.nr_order IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    LISTAGG(mci.actor_name || ' as ' || mci.role_name, ', ' ORDER BY mci.actor_rank) AS cast_list,
    LISTAGG(DISTINCT rm.movie_keyword, ', ') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCastInfo mci ON rm.movie_id = mci.movie_id
WHERE 
    rm.year_rank <= 5
GROUP BY 
    rm.movie_id, rm.movie_title, rm.production_year
ORDER BY 
    rm.production_year DESC;
