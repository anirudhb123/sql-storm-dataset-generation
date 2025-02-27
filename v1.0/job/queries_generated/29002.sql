WITH RankedTitles AS (
    SELECT 
        a.id AS aka_title_id,
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year IS NOT NULL
        AND a.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
),
PopularActors AS (
    SELECT 
        a.person_id,
        an.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.person_id, an.name
    HAVING 
        COUNT(ci.movie_id) > 10
),
DetailedMovieInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        a.production_year,
        ca.actor_name,
        m.note AS company_note
    FROM 
        title t
    JOIN 
        movie_info m ON t.id = m.movie_id
    JOIN 
        complete_cast cc ON cc.movie_id = t.id
    JOIN 
        PopularActors ca ON ca.person_id = cc.subject_id
    JOIN 
        RankedTitles a ON a.aka_title_id = cc.movie_id
)
SELECT 
    d.title_id,
    d.title,
    d.production_year,
    d.actor_name,
    d.company_note
FROM 
    DetailedMovieInfo d
WHERE 
    d.production_year BETWEEN 2000 AND 2023
ORDER BY 
    d.production_year DESC,
    d.title;
