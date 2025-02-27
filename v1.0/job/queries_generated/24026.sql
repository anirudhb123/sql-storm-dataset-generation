WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC) AS rank,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    WHERE a.production_year IS NOT NULL
    GROUP BY a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT
        r.movie_title,
        r.production_year,
        r.rank,
        r.cast_count
    FROM RankedMovies r
    WHERE r.cast_count > 1
),
PersonStats AS (
    SELECT 
        ak.name AS actor_name,
        COUNT(fm.movie_title) AS movie_appearance_count,
        AVG(CASE WHEN cg.gender = 'M' THEN 1 ELSE 0 END) AS male_actor_ratio
    FROM aka_name ak
    INNER JOIN cast_info ci ON ak.person_id = ci.person_id
    LEFT JOIN FilteredMovies fm ON ci.movie_id = (SELECT id FROM aka_title WHERE title = fm.movie_title AND production_year = fm.production_year)
    INNER JOIN name cg ON cg.id = ak.person_id
    GROUP BY ak.name
),
GenderDistribution AS (
    SELECT 
        gender,
        COUNT(*) AS actor_count
    FROM name
    GROUP BY gender
),
OverallStats AS (
    SELECT 
        (SELECT COUNT(*) FROM movie_info) AS total_movies,
        (SELECT COUNT(DISTINCT person_id) FROM cast_info) AS total_actors,
        (SELECT COUNT(DISTINCT movie_id) FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')) AS action_movies_count
)
SELECT 
    ps.actor_name,
    ps.movie_appearance_count,
    gd.actor_count AS total_gender_count,
    ods.total_movies,
    ods.total_actors,
    ods.action_movies_count,
    CASE 
        WHEN ps.movie_appearance_count > 10 THEN 'Frequent Actor'
        WHEN ps.movie_appearance_count BETWEEN 5 AND 10 THEN 'Moderate Actor'
        ELSE 'New Actor'
    END AS actor_type,
    NULLIF(CASE WHEN ps.male_actor_ratio > 0.5 THEN 'Predominantly Male' ELSE 'Diverse Gender' END, 'Predominantly Male') AS gender_diversity
FROM PersonStats ps
CROSS JOIN GenderDistribution gd, OverallStats ods
ORDER BY ps.movie_appearance_count DESC, ps.actor_name;
