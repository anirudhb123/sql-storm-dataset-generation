WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorTitleInfo AS (
    SELECT 
        coalesce(aka.name, c.name) AS actor_name,
        t.title,
        t.production_year,
        ct.kind AS role_type,
        RANK() OVER (PARTITION BY t.id ORDER BY c.nr_order) AS rank_order
    FROM 
        cast_info c
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        aka_name aka ON c.person_id = aka.person_id
    JOIN 
        role_type ct ON c.role_id = ct.id
    WHERE 
        c.nr_order <= 5
),
MovieKeywordInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    ati.actor_name,
    ati.role_type,
    COALESCE(mki.keywords, 'No Keywords') AS keywords,
    (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = rt.title_id) AS cast_count
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorTitleInfo ati ON rt.title_id = ati.title_id AND ati.rank_order = 1
LEFT JOIN 
    MovieKeywordInfo mki ON rt.title_id = mki.movie_id
WHERE 
    rt.rn <= 10
ORDER BY 
    rt.production_year DESC, 
    rt.title ASC;
