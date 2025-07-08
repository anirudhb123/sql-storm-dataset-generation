
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        LISTAGG(k.keyword, ', ') AS keywords,
        COALESCE(mi.info, 'No info') AS movie_info
    FROM title AS t
    JOIN cast_info AS ci ON t.id = ci.movie_id
    JOIN aka_name AS a ON ci.person_id = a.person_id
    JOIN movie_companies AS mc ON t.id = mc.movie_id
    JOIN company_type AS ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN keyword AS k ON mk.keyword_id = k.id
    LEFT JOIN movie_info AS mi ON t.id = mi.movie_id
    WHERE t.production_year >= 2000
    AND ct.kind LIKE '%Production%'
    GROUP BY t.id, t.title, t.production_year, a.name, ct.kind, mi.info
),
RankedMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.actor_name,
        md.company_type,
        md.keywords,
        md.movie_info,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY COUNT(md.actor_name) DESC) AS actor_rank
    FROM MovieDetails AS md
    GROUP BY md.movie_title, md.production_year, md.actor_name, md.company_type, md.keywords, md.movie_info
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.actor_name,
    rm.company_type,
    rm.keywords,
    rm.movie_info
FROM RankedMovies AS rm
WHERE rm.actor_rank <= 3
ORDER BY rm.production_year DESC, rm.actor_rank;
