
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        LISTAGG(DISTINCT m.title, ', ') WITHIN GROUP (ORDER BY m.title) AS movies
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    LEFT JOIN 
        aka_title m ON c.movie_id = m.id
    GROUP BY 
        a.person_id, a.name
)
SELECT 
    ad.name AS actor_name,
    COALESCE(ch.name, 'No Character') AS character_name,
    rm.title AS movie_title,
    rm.production_year,
    ad.movie_count,
    CASE 
        WHEN ad.movie_count > 5 THEN 'Prolific Actor'
        WHEN ad.movie_count BETWEEN 3 AND 5 THEN 'Moderate Actor'
        ELSE 'Occasional Actor' 
    END AS actor_category,
    LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
FROM 
    ActorDetails ad
JOIN 
    complete_cast cc ON ad.person_id = cc.subject_id
FULL OUTER JOIN 
    RankedMovies rm ON cc.movie_id = rm.movie_id
LEFT JOIN 
    char_name ch ON ad.person_id = ch.imdb_id AND ch.imdb_index IS NOT NULL
LEFT JOIN 
    movie_keyword mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    rm.year_rank <= 3 
    AND (ad.movie_count IS NULL OR ad.movie_count > 1)
GROUP BY 
    ad.name, ch.name, rm.title, rm.production_year, ad.movie_count
HAVING 
    COUNT(k.id) > 0 OR ch.name IS NOT NULL 
ORDER BY 
    rm.production_year DESC, ad.movie_count DESC;
