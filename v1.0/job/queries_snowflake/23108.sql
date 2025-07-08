WITH RankedMovies AS (
    SELECT
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
DirectorInfo AS (
    SELECT
        p.id AS director_id,
        p.name AS director_name,
        COUNT(DISTINCT ci.movie_id) AS directed_movies,
        MAX(CASE WHEN ci.nr_order = 1 THEN at.title END) AS first_movie_title
    FROM 
        aka_name p
    JOIN 
        cast_info ci ON p.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Director')
    GROUP BY 
        p.id, p.name
)
SELECT
    rm.title,
    rm.production_year,
    rm.total_actors,
    di.director_name,
    di.directed_movies,
    di.first_movie_title,
    COALESCE(mi.info, 'No Info Available') AS movie_info,
    CASE 
        WHEN rm.total_actors IS NULL THEN 'No Cast'
        WHEN rm.total_actors = 0 THEN 'No Actors'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.title = mi.info AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
LEFT JOIN 
    DirectorInfo di ON rm.title = di.first_movie_title
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, rm.total_actors DESC 
    NULLS LAST;
