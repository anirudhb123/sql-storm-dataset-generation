
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COALESCE(a.name, 'Unknown Actor') AS safe_actor_name,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS total_cast_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    cd.actor_name,
    cd.role_name,
    COALESCE(mk.keywords, 'No Keywords') AS movie_keywords,
    (SELECT COUNT(*)
     FROM complete_cast
     WHERE movie_id = cd.movie_id) AS complete_cast_count,
    CASE 
        WHEN cd.total_cast_count > 5 THEN 'Ensemble Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    CASE 
        WHEN rt.year_rank = 1 THEN 'Most Recent'
        ELSE 'Older'
    END AS title_recency
FROM 
    RankedTitles rt
JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON cd.movie_id = mk.movie_id
WHERE 
    rt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE 'C%')
    AND rt.production_year > 2000
ORDER BY 
    rt.production_year DESC,
    cd.actor_name ASC
LIMIT 100;
