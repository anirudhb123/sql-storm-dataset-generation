WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS year_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
MovieDetails AS (
    SELECT 
        ct.id AS cast_id,
        ct.movie_id,
        an.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        RANK() OVER (PARTITION BY ct.movie_id ORDER BY coalesce(ct.nr_order, 999) ASC) AS cast_rank
    FROM 
        cast_info ct
    JOIN 
        aka_name an ON an.person_id = ct.person_id
    JOIN 
        aka_title at ON at.id = ct.movie_id
),
ExtendedMovieInfo AS (
    SELECT 
        md.movie_id,
        COUNT(DISTINCT md.cast_id) AS total_cast,
        STRING_AGG(DISTINCT md.actor_name, ', ') AS actors_list
    FROM 
        MovieDetails md
    GROUP BY 
        md.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    em.total_cast,
    em.actors_list,
    COALESCE(ki.keyword, 'N/A') AS keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ExtendedMovieInfo em ON rt.title_id = em.movie_id
LEFT JOIN 
    (SELECT 
         mk.movie_id, 
         k.keyword
     FROM 
         movie_keyword mk
     JOIN 
         keyword k ON mk.keyword_id = k.id
    ) ki ON rt.title_id = ki.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
