
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

FilteredActors AS (
    SELECT 
        ak.id AS actor_id,
        ak.name,
        ak.person_id,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    WHERE 
        ak.name IS NOT NULL AND ak.name <> ''
    GROUP BY 
        ak.id, ak.name, ak.person_id
    HAVING 
        COUNT(ci.movie_id) > 5
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
),

MoviesWithKeywords AS (
    SELECT 
        mt.title_id,
        mt.title,
        mt.production_year,
        kw.keywords
    FROM 
        RankedTitles mt
    LEFT JOIN 
        MovieKeywords kw ON mt.title_id = kw.movie_id
    WHERE 
        mt.rank = 1 OR (mt.rank = 2 AND mt.production_year >= 2000)
)

SELECT 
    m.title,
    m.production_year,
    m.keywords,
    a.name AS lead_actor,
    COALESCE(a.movie_count, 0) AS actor_movie_count
FROM 
    MoviesWithKeywords m
LEFT JOIN 
    FilteredActors a ON a.actor_id = (
        SELECT ci.person_id 
        FROM cast_info ci 
        WHERE ci.movie_id = m.title_id
        ORDER BY ci.nr_order
        FETCH FIRST 1 ROW ONLY
    )
WHERE 
    m.keywords IS NOT NULL
ORDER BY 
    m.production_year DESC, 
    m.title;
