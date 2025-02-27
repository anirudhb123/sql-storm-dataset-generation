WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_actor_count
    FROM 
        aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, title, production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_actor_count <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COALESCE(SUM(CASE WHEN mi.info_type_id = 1 THEN 1 END), 0) AS awards_count,
        COALESCE(SUM(CASE WHEN kw.keyword IS NOT NULL THEN 1 END), 0) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN cast_info c ON tm.movie_id = c.movie_id
    LEFT JOIN aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN movie_info mi ON tm.movie_id = mi.movie_id
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        tm.movie_id, tm.title, tm.production_year
),
FinalResults AS (
    SELECT 
        md.*,
        CASE 
            WHEN awards_count > 0 THEN 'Awarded'
            WHEN keyword_count > 3 THEN 'Popular'
            ELSE 'Standard'
        END AS movie_type
    FROM 
        MovieDetails md
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_names,
    fr.movie_type,
    CASE 
        WHEN fr.movie_type = 'Awarded' THEN 'Shine Bright'
        ELSE 'Keep Watching'
    END AS recommendation
FROM 
    FinalResults fr
WHERE 
    fr.production_year > 2000
ORDER BY 
    fr.production_year DESC, fr.actor_names;