WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title ASC) AS rank_in_year
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tvseries')) 
        AND t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        s.name AS starring_actor,
        GROUP_CONCAT(DISTINCT mk.keyword ORDER BY mk.keyword) AS keywords,
        COALESCE(mi.info, 'No additional information') AS movie_info
    FROM 
        RankedMovies rm
    JOIN 
        complete_cast cc ON rm.movie_id = cc.movie_id
    JOIN 
        aka_name s ON cc.subject_id = s.id
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.rank_in_year <= 5
    GROUP BY 
        rm.movie_id, rm.movie_title, rm.production_year, s.name, mi.info
)

SELECT 
    md.movie_title,
    md.production_year,
    md.starring_actor,
    md.keywords,
    md.movie_info
FROM 
    MovieDetails md
ORDER BY 
    md.production_year DESC, 
    md.movie_title ASC;

