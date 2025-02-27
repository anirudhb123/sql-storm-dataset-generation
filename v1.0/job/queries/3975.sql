WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
CastDetails AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
), 
MovieKeywords AS (
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
    r.title_id,
    r.title,
    r.production_year,
    cd.actor_count,
    cd.actor_names,
    mk.keywords,
    CASE 
        WHEN r.rank <= 5 THEN 'Top 5 of the year'
        ELSE 'Below Top 5'
    END AS rank_status
FROM 
    RankedTitles r
LEFT JOIN 
    CastDetails cd ON r.title_id = cd.movie_id
LEFT JOIN 
    MovieKeywords mk ON r.title_id = mk.movie_id
WHERE 
    r.production_year >= 2000
ORDER BY 
    r.production_year DESC, r.rank;
