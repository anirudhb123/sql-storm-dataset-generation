
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS title_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year IS NOT NULL
),
MovieCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
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
    r.actor_name,
    r.movie_title,
    COALESCE(m.actor_count, 0) AS total_actors,
    mk.keywords,
    CASE 
        WHEN r.production_year > 2020 THEN 'Recent Release'
        ELSE 'Old Release'
    END AS release_type
FROM 
    RankedTitles r
LEFT JOIN 
    MovieCounts m ON r.aka_id = m.movie_id
LEFT JOIN 
    MovieKeywords mk ON r.aka_id = mk.movie_id
WHERE 
    r.title_rank = 1
ORDER BY 
    r.actor_name, r.production_year DESC;
