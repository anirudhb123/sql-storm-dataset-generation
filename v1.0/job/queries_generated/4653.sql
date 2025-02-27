WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY t.kind_id) AS rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actors,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        c.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.title
)
SELECT 
    rt.title,
    rt.production_year,
    cd.actors,
    cd.actor_count,
    mk.keywords,
    COALESCE(rt.rank, -1) AS title_rank
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title = cd.title
LEFT JOIN 
    MoviesWithKeywords mk ON rt.title = mk.title
WHERE 
    cd.actor_count > 3 OR mk.keywords IS NOT NULL
ORDER BY 
    rt.production_year DESC, title_rank, cd.actor_count DESC;
