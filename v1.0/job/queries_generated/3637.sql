WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
cast_summary AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id
),
movies_with_cast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cs.num_cast_members,
        cs.cast_names,
        COALESCE(MIN(mci.status_id), 999) AS min_status
    FROM 
        ranked_movies rm
    LEFT JOIN 
        complete_cast mci ON rm.movie_id = mci.movie_id
    LEFT JOIN 
        cast_summary cs ON rm.movie_id = cs.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cs.num_cast_members, cs.cast_names
)
SELECT 
    mwc.title,
    mwc.production_year,
    mwc.num_cast_members,
    mwc.cast_names,
    mwc.min_status,
    CASE 
        WHEN mwc.num_cast_members > 10 THEN 'Ensemble Cast'
        WHEN mwc.num_cast_members IS NULL THEN 'No Cast Information'
        ELSE 'Standard Cast' 
    END AS cast_type
FROM 
    movies_with_cast mwc
WHERE 
    mwc.production_year >= 2000
    AND mwc.min_status < 999
ORDER BY 
    mwc.production_year DESC, 
    mwc.num_cast_members DESC
LIMIT 50;
