WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM title m
    JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id, m.title, m.production_year
),
TopMovies AS (
    SELECT movie_id, title, production_year
    FROM RankedMovies
    WHERE rank <= 3
),
MovieDetails AS (
    SELECT 
        tm.title AS movie_title,
        COALESCE(ak.name, 'Unknown') AS actor_name,
        ct.kind AS company_type,
        mi.info AS movie_info
    FROM TopMovies tm
    LEFT JOIN complete_cast cc ON tm.movie_id = cc.movie_id
    LEFT JOIN aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi ON tm.movie_id = mi.movie_id AND mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'description' LIMIT 1
    )
)
SELECT 
    md.movie_title,
    md.actor_name,
    md.company_type,
    md.movie_info,
    COUNT(DISTINCT ak.id) AS total_actors,
    SUM(CASE WHEN md.movie_info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
FROM MovieDetails md
LEFT JOIN movie_keyword mk ON md.movie_id = mk.movie_id
LEFT JOIN keyword kt ON mk.keyword_id = kt.id
GROUP BY md.movie_title, md.actor_name, md.company_type, md.movie_info
ORDER BY md.movie_title;
