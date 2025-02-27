WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        a.name AS director_name,
        k.keyword AS movie_keyword,
        comp.name AS company_name,
        ci.person_role_id AS role_id,
        ci.nr_order AS cast_order
    FROM title t
    JOIN aka_title at ON at.title = t.title
    JOIN cast_info ci ON ci.movie_id = at.movie_id
    JOIN aka_name a ON a.person_id = ci.person_id
    JOIN movie_keyword mk ON mk.movie_id = t.id
    JOIN keyword k ON k.id = mk.keyword_id
    JOIN movie_companies mc ON mc.movie_id = t.id
    JOIN company_name comp ON comp.id = mc.company_id
    WHERE 
        t.production_year >= 2000
        AND a.name IS NOT NULL
        AND k.keyword IS NOT NULL
),
DirectorCount AS (
    SELECT 
        director_name,
        COUNT(*) AS movie_count
    FROM MovieDetails
    GROUP BY director_name
),
TopDirectors AS (
    SELECT 
        director_name,
        movie_count
    FROM DirectorCount
    WHERE movie_count > 5
)
SELECT 
    md.movie_title,
    md.production_year,
    md.company_name,
    td.director_name,
    td.movie_count
FROM MovieDetails md
JOIN TopDirectors td ON md.director_name = td.director_name
ORDER BY md.production_year DESC, td.movie_count DESC, md.cast_order;
