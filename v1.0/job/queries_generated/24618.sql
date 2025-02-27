WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title ASC) AS rank_within_year
    FROM title t
    WHERE t.production_year IS NOT NULL
),
CompanyMovieCount AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM movie_companies mc
    GROUP BY mc.movie_id
),
TopMovies AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        c.company_count,
        rank_within_year
    FROM RankedTitles rt
    LEFT JOIN CompanyMovieCount c ON rt.title_id = c.movie_id
    WHERE rt.rank_within_year <= 10  -- Consider top 10 titles from each year
),
ActorsPerMovie AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(apm.actor_count, 0) AS actor_count,
        COALESCE(tm.company_count, 0) AS company_count,
        CASE 
            WHEN COALESCE(apm.actor_count, 0) > 5 THEN 'Popular'
            WHEN COALESCE(apm.actor_count, 0) = 0 THEN 'No Actors'
            ELSE 'Few Actors'
        END AS actor_category
    FROM TopMovies tm
    LEFT JOIN ActorsPerMovie apm ON tm.title_id = apm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.company_count,
    md.actor_category,
    CASE 
        WHEN md.actor_count IS NULL THEN 'Unknown'
        WHEN md.actor_count = 1 THEN CONCAT(md.title, ' has 1 notable actor')
        ELSE CONCAT(md.title, ' features ', md.actor_count, ' actors!')
    END AS actor_description
FROM MovieDetails md
WHERE 
    md.production_year >= 2000 
    AND (md.actor_count > 0 OR md.company_count > 0)
ORDER BY md.production_year DESC, md.actor_count DESC;
