
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS company_types,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM title t
    JOIN movie_info mi ON t.id = mi.movie_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type c ON mc.company_type_id = c.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'directed by')
        AND t.production_year BETWEEN 2000 AND 2023
    GROUP BY t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title, 
        production_year,
        actors,
        company_types,
        keywords
    FROM MovieDetails
    WHERE actors IS NOT NULL AND company_types IS NOT NULL
)
SELECT 
    f.movie_title,
    f.production_year,
    f.actors,
    f.company_types,
    f.keywords,
    LENGTH(f.movie_title) AS title_length,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id IN (SELECT id FROM title WHERE title = f.movie_title)) AS actor_count
FROM FilteredMovies f
ORDER BY f.production_year DESC, title_length DESC
LIMIT 50;
