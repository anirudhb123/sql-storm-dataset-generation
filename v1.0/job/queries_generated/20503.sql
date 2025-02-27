WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.production_year DESC) AS year_rank,
        COUNT(DISTINCT cast_info.person_id) OVER (PARTITION BY title.id) AS total_cast
    FROM 
        title
    LEFT JOIN 
        aka_title ON aka_title.movie_id = title.id
    LEFT JOIN 
        cast_info ON cast_info.movie_id = title.id
    WHERE 
        title.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        year_rank,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5 AND total_cast > 3
),
MovieDetails AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COALESCE(mc.note, 'No Note') AS company_note,
        STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
        COUNT(DISTINCT pi.info) AS info_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = fm.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = fm.movie_id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = fm.movie_id
    LEFT JOIN 
        person_info pi ON pi.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = fm.movie_id)
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year, mc.note
),
NULLHandling AS (
    SELECT 
        md.*,
        CASE 
            WHEN info_count > 0 THEN 'Has Info' 
            ELSE 'No Info' 
        END AS info_status
    FROM 
        MovieDetails md
)
SELECT 
    nm.name AS actor_name,
    nm.gender AS actor_gender,
    nh.info AS additional_info,
    nh.info_status,
    nm.md5sum AS actor_md5sum,
    nh.movie_id,
    nh.title AS movie_title,
    nh.production_year,
    nh.keywords
FROM 
    NULLHandling nh
INNER JOIN 
    aka_name nm ON nm.person_id IN (SELECT person_id FROM cast_info WHERE movie_id = nh.movie_id)
WHERE 
    nh.production_year BETWEEN 2000 AND 2020
ORDER BY 
    nh.production_year DESC, actor_name;

