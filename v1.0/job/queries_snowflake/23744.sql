
WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        a.person_id,
        a.name AS actor_name,
        t.title,
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
TopActors AS (
    SELECT 
        person_id,
        COUNT(DISTINCT aka_id) AS movie_count
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 3
    GROUP BY 
        person_id
    HAVING 
        COUNT(DISTINCT aka_id) >= 2
),
MoviesWithKeywords AS (
    SELECT 
        t.id AS title_id,
        t.title,
        k.keyword,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year > 2000
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT mwk.title_id) AS keyword_movie_count,
    AVG(mwk.production_year) AS avg_year,
    LISTAGG(DISTINCT mwk.keyword, ', ') WITHIN GROUP (ORDER BY mwk.keyword) AS associated_keywords
FROM 
    RankedTitles a 
LEFT JOIN 
    MoviesWithKeywords mwk ON a.title = mwk.title
WHERE 
    a.title_rank <= 3
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT mwk.title_id) > 1
ORDER BY 
    keyword_movie_count DESC
LIMIT 10;
