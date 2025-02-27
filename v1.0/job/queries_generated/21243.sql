WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS ranking
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'feature%')
),
MovieCast AS (
    SELECT 
        m.movie_id,
        a.name AS actor_name,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        RankedMovies m ON c.movie_id = m.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(STRING_AGG(DISTINCT mc.actor_name ORDER BY mc.actor_order), 'No Cast') AS cast,
    CASE 
        WHEN COUNT(mk.keywords) > 0 THEN 'Has Keywords' 
        ELSE 'No Keywords' 
    END AS keyword_status,
    COUNT(mc.actor_name) AS actor_count
FROM 
    RankedMovies r
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    MovieCast mc ON r.movie_id = mc.movie_id
GROUP BY 
    r.movie_id, r.title, r.production_year, mk.keywords
HAVING 
    COUNT(DISTINCT mc.actor_name) > 5 
    OR (r.production_year IS NULL)
ORDER BY 
    r.production_year DESC,
    r.title
LIMIT 50;
