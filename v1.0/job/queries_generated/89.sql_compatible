
WITH MovieDetails AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        AVG(COALESCE(ci.nr_order, 0)) AS avg_order
    FROM aka_title a
    LEFT JOIN movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    WHERE a.production_year >= 2000
    GROUP BY a.title, a.production_year, a.id
),
CastStats AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movies_played,
        ROW_NUMBER() OVER (ORDER BY COUNT(c.movie_id) DESC) AS rn
    FROM cast_info c
    GROUP BY c.person_id
),
TopActors AS (
    SELECT 
        p.id AS person_id,
        p.name AS actor_name,
        cs.movies_played
    FROM name p
    JOIN CastStats cs ON p.id = cs.person_id
    WHERE cs.movies_played > 5
),
RecentMovies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        LENGTH(md.movie_title) AS title_length,
        CASE 
            WHEN md.production_year IS NULL THEN 'No Year'
            WHEN md.production_year < 2010 THEN 'Pre-2010'
            ELSE 'Post-2010'
        END AS year_category
    FROM MovieDetails md
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.title_length,
    rm.year_category,
    ta.actor_name,
    ta.movies_played
FROM RecentMovies rm
JOIN TopActors ta ON rm.production_year = ta.movies_played
WHERE rm.year_category = 'Post-2010'
ORDER BY rm.production_year DESC, rm.title_length DESC
FETCH FIRST 25 ROWS ONLY; 
