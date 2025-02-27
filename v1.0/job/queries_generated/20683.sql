WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS num_actors,
        SUM(CASE WHEN a.production_year IS NOT NULL THEN 1 ELSE 0 END) AS valid_year_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM aka_title a
    LEFT JOIN cast_info c ON a.id = c.movie_id
    GROUP BY a.id, a.title, a.production_year
), FilteredActors AS (
    SELECT 
        DISTINCT c.person_id,
        c.movie_id,
        r.production_year,
        c.nr_order,
        CASE 
            WHEN c.note = 'minor' THEN 'Supporting Role'
            WHEN c.note IS NULL THEN 'Unknown Role'
            ELSE 'Lead Role'
        END AS role_description
    FROM cast_info c
    JOIN RankedMovies r ON c.movie_id = r.id
    WHERE r.rank <= 5
), MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword m
    JOIN keyword k ON m.keyword_id = k.id
    GROUP BY m.movie_id
), FinalResults AS (
    SELECT 
        a.title,
        a.production_year,
        fa.role_description,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(fa.person_id) AS actor_count
    FROM aka_title a
    JOIN FilteredActors fa ON a.id = fa.movie_id
    LEFT JOIN MovieKeywords mk ON a.id = mk.movie_id
    GROUP BY a.id, a.title, a.production_year, fa.role_description
)
SELECT 
    title,
    production_year,
    role_description,
    keywords,
    actor_count
FROM FinalResults
WHERE actor_count > 2 AND production_year IS NOT NULL
ORDER BY production_year DESC, actor_count DESC
LIMIT 10;
