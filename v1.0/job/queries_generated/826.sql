WITH ActorMovies AS (
    SELECT 
        a.person_id,
        a.name,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.movie_id) OVER (PARTITION BY a.person_id) AS movie_count,
        ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
), 
MostActiveActors AS (
    SELECT 
        person_id,
        name,
        movie_count
    FROM ActorMovies
    WHERE movie_count > 5
), 
RecentMovies AS (
    SELECT 
        person_id,
        title,
        production_year
    FROM ActorMovies
    WHERE recent_movie_rank = 1
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.imdb_id
    JOIN company_type ct ON mc.company_type_id = ct.id
), 
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    ma.name AS actor_name,
    STRING_AGG(DISTINCT rm.title, ', ') AS recent_movies,
    STRING_AGG(DISTINCT ci.company_name, ', ') AS companies_involved,
    STRING_AGG(DISTINCT ki.keywords, ', ') AS keywords
FROM MostActiveActors ma
LEFT JOIN RecentMovies rm ON ma.person_id = rm.person_id
LEFT JOIN CompanyInfo ci ON rm.title = ci.movie_id
LEFT JOIN KeywordInfo ki ON rm.title = ki.movie_id
WHERE ma.name IS NOT NULL
GROUP BY ma.person_id, ma.name
ORDER BY ma.movie_count DESC;
