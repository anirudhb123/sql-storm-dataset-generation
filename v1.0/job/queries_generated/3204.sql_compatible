
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT cc.person_id) AS actor_count,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT cc.person_id) DESC) AS rank_by_actors,
        a.id AS movie_id
    FROM aka_title AS a
    JOIN cast_info AS cc ON a.id = cc.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
CompanyContributions AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(DISTINCT c.id) AS company_count,
        RANK() OVER (PARTITION BY mc.movie_id ORDER BY COUNT(DISTINCT c.id) DESC) AS rank_by_companies
    FROM movie_companies AS mc
    JOIN company_name AS c ON mc.company_id = c.id
    GROUP BY mc.movie_id, c.name
),
MoviesWithKeywords AS (
    SELECT 
        a.id AS movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM aka_title AS a
    JOIN movie_keyword AS mk ON a.id = mk.movie_id
    JOIN keyword AS k ON mk.keyword_id = k.id
    WHERE a.production_year >= 2000
    GROUP BY a.id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(rm.actor_count, 0) AS actor_count,
    COALESCE(cc.company_count, 0) AS company_count,
    COALESCE(mw.keywords, 'No Keywords') AS keywords
FROM RankedMovies AS rm
LEFT JOIN CompanyContributions AS cc ON rm.movie_id = cc.movie_id
LEFT JOIN MoviesWithKeywords AS mw ON rm.movie_id = mw.movie_id
WHERE rm.rank_by_actors <= 5
ORDER BY rm.production_year DESC, rm.actor_count DESC;
