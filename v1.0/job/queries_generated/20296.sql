WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(distinct c.person_id) OVER (PARTITION BY m.id) AS cast_count,
        COUNT(distinct k.keyword) OVER (PARTITION BY m.id) AS keyword_count,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS year_rank,
        RANK() OVER (ORDER BY m.production_year) AS year_rank_distinct
    FROM 
        aka_title m
    LEFT JOIN movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL 
        AND m.production_year >= 2000
),
PopularMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.keyword_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.cast_count > 5 
        AND rm.year_rank <= 10
),
AllGenres AS (
    SELECT 
        DISTINCT m.id AS movie_id, 
        k.kind AS genre
    FROM 
        aka_title m
    INNER JOIN kind_type k ON m.kind_id = k.id
),
MovieDetails AS (
    SELECT 
        pm.title,
        pm.production_year,
        STRING_AGG(DISTINCT g.genre, ', ') AS genres,
        COUNT(DISTINCT cc.id) AS company_count,
        COUNT(DISTINCT pi.id) AS person_info_count
    FROM 
        PopularMovies pm
    LEFT JOIN movie_companies mc ON pm.movie_id = mc.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN person_info pi ON pi.person_id IN (SELECT c.person_id FROM cast_info c WHERE c.movie_id = pm.movie_id)
    LEFT JOIN AllGenres g ON pm.movie_id = g.movie_id
    GROUP BY 
        pm.movie_id, pm.title, pm.production_year
)
SELECT 
    md.title,
    md.production_year,
    COALESCE(md.genres, 'No genres available') AS genres,
    md.company_count,
    md.person_info_count,
    CASE 
        WHEN md.person_info_count >= 10 THEN 'Highly Informative'
        WHEN md.person_info_count BETWEEN 5 AND 9 THEN 'Moderately Informative'
        ELSE 'Minimal Information'
    END AS info_level,
    CASE 
        WHEN SUM(CASE WHEN md.company_count IS NULL THEN 1 ELSE 0 END) > 0 THEN 'Includes Unknown Companies'
        ELSE 'All Companies Known'
    END AS companies_status
FROM 
    MovieDetails md
WHERE 
    md.company_count IS NOT NULL
ORDER BY 
    md.production_year DESC, md.title;
