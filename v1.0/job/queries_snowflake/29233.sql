
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
        LISTAGG(DISTINCT c.kind, ', ') WITHIN GROUP (ORDER BY c.kind) AS company_types
    FROM
        aka_title AS t
    JOIN
        movie_keyword AS mk ON t.id = mk.movie_id
    JOIN
        keyword AS k ON mk.keyword_id = k.id
    JOIN
        complete_cast AS cc ON t.id = cc.movie_id
    JOIN
        cast_info AS ci ON cc.subject_id = ci.person_id
    JOIN
        aka_name AS a ON ci.person_id = a.person_id
    JOIN
        movie_companies AS mc ON t.id = mc.movie_id
    JOIN
        company_type AS c ON mc.company_type_id = c.id
    WHERE
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
),

FilteredMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actors,
        md.keywords,
        md.company_types
    FROM 
        MovieDetails md
    WHERE 
        md.actors IS NOT NULL AND md.keywords IS NOT NULL
)

SELECT 
    md.*,
    LENGTH(md.actors) AS actor_count,
    LENGTH(md.keywords) AS keyword_count,
    LENGTH(md.company_types) AS company_count
FROM 
    FilteredMovies md
ORDER BY 
    md.production_year DESC, actor_count DESC;
