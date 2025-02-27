WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        COALESCE(t.title, 'Unknown Title') AS title,
        COALESCE(c.name, 'Unknown Company') AS company_name,
        m.production_year,
        (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = m.id) AS total_cast,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN movie_companies mc ON mc.movie_id = m.id
    LEFT JOIN company_name c ON c.id = mc.company_id
    LEFT JOIN movie_keyword mk ON mk.movie_id = m.id
    GROUP BY 
        m.id, t.title, c.name, m.production_year
),
FullCastInfo AS (
    SELECT 
        k.id AS keyword_id,
        k.keyword,
        t.production_year,
        a.name AS actor_name,
        ai.note AS actor_note,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY a.name) AS actor_rank,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_by_cast
    FROM 
        aka_name a
    JOIN cast_info ci ON ci.person_id = a.person_id
    JOIN aka_title t ON t.id = ci.movie_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    LEFT JOIN person_info ai ON ai.person_id = a.person_id
    JOIN complete_cast cc ON cc.movie_id = t.id
    GROUP BY 
        k.id, k.keyword, t.production_year, a.name, ai.note
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.total_cast,
    md.keyword_count,
    fki.actor_name AS top_actor,
    fki.actor_note AS actor_notes,
    fki.year_rank,
    COALESCE(fki.rank_by_cast, 0) AS cast_rank
FROM 
    MovieDetails md
LEFT JOIN FullCastInfo fki ON fki.production_year = md.production_year
WHERE 
    md.keyword_count > 1
ORDER BY 
    md.production_year DESC, 
    md.keyword_count DESC, 
    fki.actor_rank ASC
LIMIT 100
OFFSET 0;

