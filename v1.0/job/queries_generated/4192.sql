WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        RANK() OVER (PARTITION BY mt.production_year ORDER BY mc.company_id) AS rank_year
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(mk.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
TopCast AS (
    SELECT 
        ci.movie_id, 
        STRING_AGG(a.name, ', ') AS actors
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.role_id IN (SELECT id FROM role_type WHERE role = 'actor')
    GROUP BY 
        ci.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(tc.actors, 'No Actors') AS actors,
    CASE 
        WHEN rm.rank_year <= 5 THEN 'Top Rated in Year'
        ELSE 'Other'
    END AS rating_category
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    TopCast tc ON rm.movie_id = tc.movie_id
WHERE 
    rm.production_year >= 2000
ORDER BY 
    rm.production_year DESC, 
    rm.title;
