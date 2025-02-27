WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        RANK() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rank_year,
        COUNT(ki.keyword) OVER (PARTITION BY a.person_id) AS keyword_count,
        (SELECT COUNT(DISTINCT mc.company_id) 
         FROM movie_companies mc 
         WHERE mc.movie_id = t.id 
         AND mc.company_type_id IN (
             SELECT id FROM company_type WHERE kind = 'Distributor'
         )) AS distributor_count
    FROM 
        aka_name a
    INNER JOIN 
        cast_info ci ON a.person_id = ci.person_id
    INNER JOIN 
        aka_title t ON ci.movie_id = t.id 
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    WHERE 
        a.name IS NOT NULL 
        AND t.production_year IS NOT NULL 
        AND (SELECT COUNT(*) 
             FROM movie_info mi 
             WHERE mi.movie_id = t.id 
             AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')) > 0
        AND EXISTS (
            SELECT 1 
            FROM complete_cast cc 
            WHERE cc.movie_id = t.id 
            AND cc.subject_id = a.person_id 
            AND cc.status_id IS NULL
        )
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN rank_year = 1 THEN 'Latest'
            WHEN rank_year <= 3 THEN 'Recent'
            ELSE 'Older'
        END AS movie_age_category
    FROM 
        RankedMovies
)

SELECT 
    fm.aka_id,
    fm.aka_name,
    fm.movie_title,
    fm.production_year,
    fm.keyword_count,
    fm.distributor_count,
    CASE 
        WHEN fm.distributor_count IS NULL THEN 'No Distributor Info'
        ELSE 'Distributors Available'
    END AS distributor_info,
    RANK() OVER (ORDER BY fm.production_year DESC) AS global_rank
FROM 
    FilteredMovies fm
WHERE 
    (fm.rank_year <= 3 OR fm.keyword_count > 5)
ORDER BY 
    fm.production_year DESC;