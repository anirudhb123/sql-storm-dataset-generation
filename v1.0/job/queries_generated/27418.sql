WITH MovieStats AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        COALESCE((SELECT STRING_AGG(DISTINCT cn.name, ', ')
                   FROM movie_companies mc
                   JOIN company_name cn ON mc.company_id = cn.id
                   WHERE mc.movie_id = m.id), 'N/A') AS production_companies
    FROM title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    LEFT JOIN aka_name a ON c.person_id = a.person_id
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY m.id, m.title, m.production_year
),
GenreStats AS (
    SELECT 
        DISTINCT m.movie_id,
        kt.kind AS genre
    FROM movie_companies mc
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN title m ON mc.movie_id = m.id
    JOIN kind_type kt ON m.kind_id = kt.id
)
SELECT 
    ms.movie_id,
    ms.movie_title,
    ms.production_year,
    ms.cast_count,
    ms.cast_names,
    ms.keywords,
    ms.production_companies,
    STRING_AGG(DISTINCT gs.genre, ', ') AS genres
FROM MovieStats ms
LEFT JOIN GenreStats gs ON ms.movie_id = gs.movie_id
GROUP BY ms.movie_id, ms.movie_title, ms.production_year, ms.cast_count, ms.cast_names, ms.production_companies
ORDER BY ms.production_year DESC, ms.movie_title;
