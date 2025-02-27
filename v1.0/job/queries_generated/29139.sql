WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title AS movie_title,
        aka_title.production_year,
        row_number() OVER (PARTITION BY aka_title.production_year ORDER BY title.title) AS rank
    FROM 
        title 
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    WHERE 
        aka_title.production_year IS NOT NULL
),
AggregatedNames AS (
    SELECT 
        aka_name.person_id,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS all_names,
        COUNT(DISTINCT aka_name.id) AS name_count
    FROM 
        aka_name
    GROUP BY 
        aka_name.person_id
),
MovieDetails AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        SUM(CASE WHEN movie_info.info_type_id = info_type.id THEN 1 ELSE 0 END) AS info_count,
        COUNT(DISTINCT movie_keyword.keywords) AS keyword_count
    FROM 
        title
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    LEFT JOIN 
        info_type ON movie_info.info_type_id = info_type.id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id
)
SELECT 
    rt.rank,
    rt.production_year,
    rt.movie_title,
    an.all_names,
    md.info_count,
    md.keyword_count
FROM 
    RankedTitles rt
LEFT JOIN 
    AggregatedNames an ON rt.title_id IN (
        SELECT 
            cast_info.movie_id 
        FROM 
            cast_info 
        WHERE 
            cast_info.person_id IN (
                SELECT 
                    aka_name.person_id 
                FROM 
                    aka_name 
                WHERE 
                    aka_name.name ILIKE '%Smith%'
            )
    )
LEFT JOIN 
    MovieDetails md ON rt.title_id = md.movie_id
WHERE 
    rt.rank <= 10
ORDER BY 
    rt.production_year, rt.rank;
