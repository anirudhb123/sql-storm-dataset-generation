WITH RankedActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        RANK() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    GROUP BY 
        ak.person_id, ak.name
),
FeaturedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        CASE
            WHEN mt.production_year >= 2020 THEN 'Recent'
            WHEN mt.production_year >= 2000 THEN '2000s Era'
            ELSE 'Classic'
        END AS era,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
    GROUP BY 
        mt.id, mt.title, mt.production_year, mt.kind_id
),
HighRatingMovies AS (
    SELECT 
        fc.movie_id,
        COUNT(DISTINCT fc.subject_id) AS cast_count,
        SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN 1 ELSE 0 END) AS rating_info_count
    FROM 
        complete_cast fc
    JOIN 
        movie_info mi ON fc.movie_id = mi.movie_id
    WHERE 
        mi.note IS NULL
    GROUP BY 
        fc.movie_id
    HAVING 
        COUNT(DISTINCT fc.subject_id) > 3 AND SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN 1 ELSE 0 END) > 0
)
SELECT 
    mv.movie_id,
    mv.title,
    mv.production_year,
    mv.era,
    ra.name AS top_actor,
    ra.movie_count,
    hcm.cast_count,
    hcm.rating_info_count,
    COALESCE(mk.keyword_count, 0) AS total_keywords
FROM 
    FeaturedMovies mv
JOIN 
    RankedActors ra ON ra.movie_count > 0
JOIN 
    HighRatingMovies hcm ON mv.movie_id = hcm.movie_id
LEFT JOIN 
    (SELECT movie_id, COUNT(*) AS keyword_count FROM movie_keyword GROUP BY movie_id) mk ON mv.movie_id = mk.movie_id
WHERE 
    ra.rank <= 5 
ORDER BY 
    mv.production_year DESC, mv.title
LIMIT 100;