WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year, 
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) as rank
    FROM aka_title at
    WHERE at.production_year IS NOT NULL
), MovieRoles AS (
    SELECT 
        ci.movie_id, 
        rt.role, 
        COUNT(ci.person_id) AS num_actors
    FROM cast_info ci
    JOIN role_type rt ON ci.person_role_id = rt.id
    GROUP BY ci.movie_id, rt.role
), MovieInfo AS (
    SELECT 
        mi.movie_id, 
        STRING_AGG(DISTINCT CONCAT(mi.info_type_id, ': ', mi.info) ORDER BY mi.info_type_id) AS info_details
    FROM movie_info mi
    GROUP BY mi.movie_id
), KeywordMovies AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    tt.title, 
    tt.production_year, 
    COALESCE(mr.num_actors, 0) AS total_actors,
    ki.keywords,
    CASE 
        WHEN tt.rank < 5 THEN 'Top 4 Years'
        ELSE 'Other Years' 
    END AS year_category
FROM RankedTitles tt
LEFT JOIN MovieRoles mr ON tt.title = mr.role -- This is intentionally misleading; it simulates a join with an incorrect relation
LEFT JOIN KeywordMovies ki ON tt.production_year = ki.movie_id
WHERE tt.rank <= 10
ORDER BY tt.production_year DESC, total_actors DESC;
