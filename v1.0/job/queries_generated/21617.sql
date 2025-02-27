WITH RecursiveMovieCTE AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', ' ORDER BY cn.name), 'Unknown') AS company_names,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
),
TopMovies AS (
    SELECT
        *,
        RANK() OVER (ORDER BY cast_count DESC, production_year DESC) AS movie_rank
    FROM 
        RecursiveMovieCTE
    WHERE
        company_names IS NOT NULL
),
BestMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year, 
        company_names
    FROM 
        TopMovies
    WHERE 
        movie_rank <= 10
),
ExplainedMovies AS (
    SELECT 
        bm.movie_id,
        bm.movie_title,
        bm.production_year,
        bm.company_names,
        (SELECT COUNT(DISTINCT person_id) 
         FROM cast_info ci 
         WHERE ci.movie_id = bm.movie_id AND ci.note LIKE '%lead%') AS lead_actors_count,
        (SELECT MAX(mi.info) 
         FROM movie_info mi 
         WHERE mi.movie_id = bm.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')) AS synopsis
    FROM 
        BestMovies bm
)
SELECT 
    em.movie_title,
    em.production_year,
    em.company_names,
    CASE 
        WHEN em.lead_actors_count > 5 THEN 'Major Studio'
        WHEN em.lead_actors_count BETWEEN 2 AND 5 THEN 'Independent'
        ELSE 'Unknown Studio'
    END AS studio_type,
    COALESCE(em.synopsis, 'No synopsis available') AS synopsis
FROM 
    ExplainedMovies em
WHERE 
    EXISTS (
        SELECT 1 
        FROM movie_keyword mk 
        WHERE mk.movie_id = em.movie_id 
        INTERSECT 
        SELECT 1 
        FROM keyword k 
        WHERE k.keyword LIKE '%award%'
    )
ORDER BY 
    em.production_year DESC, 
    studio_type;
