WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast <= 10
),
MovieDetails AS (
    SELECT 
        tm.title,
        COALESCE(array_agg(DISTINCT ak.name ORDER BY ak.name NULLS LAST), '{}') AS actors,
        COALESCE(array_agg(DISTINCT k.keyword ORDER BY k.keyword NULLS LAST), '{}') AS keywords,
        COALESCE(array_agg(DISTINCT ci.nr_order), 0) AS total_roles,
        CASE 
            WHEN COUNT(DISTINCT ci.role_id) > 5 THEN 'Diverse Roles'
            ELSE 'Limited Roles'
        END AS role_diversity
    FROM 
        TopMovies tm
    LEFT JOIN 
        cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.actors,
    md.keywords,
    md.total_roles,
    md.role_diversity,
    CASE 
        WHEN md.total_roles IS NULL THEN 'No Roles' 
        ELSE 'Roles Exist' 
    END AS role_status,
    LEAD(md.title) OVER (ORDER BY md.production_year) AS next_movie
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2020
ORDER BY 
    md.production_year DESC;
