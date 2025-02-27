
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ci.person_id,
        a.name AS actor_name,
        COALESCE(MAX(CASE WHEN r.role = 'Director' THEN 'Yes' END), 'No') AS is_director,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, a.name
),
MovieKeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.is_director,
    ad.movies_count,
    COALESCE(mks.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) 
     FROM complete_cast cc 
     WHERE cc.movie_id = rm.movie_id AND cc.status_id IS NULL) AS pending_cast_count,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = rm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')) AS rating_count,
    RANK() OVER (PARTITION BY rm.production_year ORDER BY COUNT(ad.person_id) DESC) AS movie_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.movie_id = ad.movies_count
LEFT JOIN 
    MovieKeywordStats mks ON rm.movie_id = mks.movie_id
LEFT JOIN 
    movie_companies mc ON rm.movie_id = mc.movie_id
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, ad.actor_name, ad.is_director, ad.movies_count, mks.keywords
HAVING 
    COUNT(ad.actor_name) > 2 
ORDER BY 
    rm.production_year DESC, movie_rank;
