
WITH RECURSIVE CastMovies AS (
    SELECT 
        c.id AS cast_info_id,
        c.movie_id,
        c.person_id,
        COALESCE(a.name, ch.name, n.name) AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM cast_info c
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN char_name ch ON c.person_id = ch.imdb_id
    LEFT JOIN name n ON c.person_id = n.imdb_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        k.keyword,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types,
        STRING_AGG(DISTINCT ca.actor_name, ', ') AS cast
    FROM aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN CastMovies ca ON m.id = ca.movie_id
    GROUP BY m.id, m.title, m.production_year, k.keyword
),
SelectedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.company_types,
        md.cast
    FROM MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2020
        AND md.keyword ILIKE '%action%'
)
SELECT 
    sm.title AS movie_title,
    sm.production_year,
    sm.keyword AS associated_keyword,
    sm.company_types AS production_company_types,
    sm.cast AS main_cast
FROM SelectedMovies sm
ORDER BY sm.production_year DESC;
