WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank_by_title,
        COUNT(*) OVER (PARTITION BY m.production_year) AS total_movies
    FROM 
        aka_title m
    WHERE 
        m.kind_id IN (SELECT kin.id FROM kind_type kin WHERE kin.kind LIKE 'feature%')
        AND m.production_year IS NOT NULL
        AND (
            EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = m.movie_id AND mk.keyword_id IN (SELECT k.id FROM keyword k WHERE k.keyword LIKE '%thriller%'))
            OR
            NOT EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = m.movie_id AND mi.info_type_id = (SELECT it.id FROM info_type it WHERE it.info = 'Synopsis' LIMIT 1))
        )
),
SelectedMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        CASE 
            WHEN rm.rank_by_title <= rm.total_movies / 2 THEN 'First Half'
            ELSE 'Second Half'
        END AS title_half
    FROM 
        RankedMovies rm
),
MovieDetails AS (
    SELECT 
        sm.movie_id,
        sm.title,
        sm.production_year,
        COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'Unknown') AS actors,
        COALESCE(STRING_AGG(DISTINCT cn.name, ', '), 'Unknown Company') AS companies,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        SelectedMovies sm
    LEFT JOIN 
        cast_info ci ON ci.movie_id = sm.movie_id
    LEFT JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = sm.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = sm.movie_id
    GROUP BY 
        sm.movie_id, sm.title, sm.production_year, sm.title_half
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.title_half,
    md.actors,
    md.companies,
    md.keyword_count,
    CASE 
        WHEN md.keyword_count > 5 THEN 'High Keyword Count'
        WHEN md.keyword_count BETWEEN 1 AND 5 THEN 'Moderate Keyword Count'
        ELSE 'No Keywords'
    END AS keyword_classification
FROM 
    MovieDetails md
WHERE 
    md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.title_half DESC, 
    md.production_year ASC, 
    md.title;

