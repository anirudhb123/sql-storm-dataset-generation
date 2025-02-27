
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ak.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info c ON mt.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
    HAVING 
        COUNT(DISTINCT ak.person_id) > 5
),
MovieWithInfo AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.actor_count,
        rm.actor_names,
        mi.info AS additional_info,
        mt.kind AS movie_kind
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id
    LEFT JOIN 
        kind_type mt ON mt.id = (SELECT kind_id FROM aka_title WHERE id = rm.movie_id LIMIT 1)
)
SELECT 
    mwi.title,
    mwi.production_year,
    mwi.actor_count,
    mwi.actor_names,
    mwi.additional_info,
    mwi.movie_kind
FROM 
    MovieWithInfo mwi
ORDER BY 
    mwi.production_year DESC, 
    mwi.actor_count DESC;
