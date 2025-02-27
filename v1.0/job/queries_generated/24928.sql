WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count,
        SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        SUM(CASE WHEN cc.kind = 'Director' THEN 1 ELSE 0 END) AS director_count,
        STRING_AGG(DISTINCT tit.title, ', ') AS titles
    FROM 
        cast_info ca
    JOIN 
        aka_name an ON ca.person_id = an.person_id
    JOIN 
        title tit ON ca.movie_id = tit.id
    LEFT JOIN 
        person_info p ON ca.person_id = p.person_id AND p.info_type_id = 1  -- assuming info_type_id 1 is gender
    JOIN 
        comp_cast_type cc ON ca.role_id = cc.id
    GROUP BY 
        ca.person_id
),
MoviesWithActors AS (
    SELECT 
        tit.title,
        tit.production_year,
        ah.person_id,
        ah.movie_count,
        ah.female_count,
        ah.director_count,
        ah.titles
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_companies mc ON mc.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
    JOIN 
        title tit ON mc.movie_id = tit.id
    WHERE 
        tit.production_year IS NOT NULL
)
SELECT 
    mwa.title,
    mwa.production_year,
    absolutes.female_percentage,
    CASE 
        WHEN absolutes.director_count > 0 THEN 'Yes' ELSE 'No' 
    END AS is_director,
    mw.role_count,
    CASE 
        WHEN mw.role_count IS NULL THEN 'No Roles' ELSE 'Has Roles' 
    END AS role_status
FROM 
    MoviesWithActors mwa
JOIN 
    (
        SELECT 
            person_id,
            COUNT(DISTINCT role_id) AS role_count,
            100.0 * SUM(CASE WHEN female_count > 0 THEN 1 ELSE 0 END) / COUNT(*) AS female_percentage
        FROM 
            (
                SELECT 
                    ca.person_id,
                    COUNT(ca.role_id) AS role_count,
                    SUM(CASE WHEN p.gender = 'F' THEN 1 ELSE 0 END) AS female_count
                FROM 
                    cast_info ca
                LEFT JOIN 
                    person_info p ON ca.person_id = p.person_id AND p.info_type_id = 1
                GROUP BY 
                    ca.person_id
            ) AS temp
        GROUP BY 
            person_id
    ) AS absolutes ON mwa.person_id = absolutes.person_id
LEFT JOIN 
    (
        SELECT 
            person_id,
            COUNT(*) AS role_count
        FROM 
            cast_info
        WHERE 
            note IS NOT NULL OR note != ''
        GROUP BY 
            person_id
    ) AS mw ON mwa.person_id = mw.person_id
ORDER BY 
    mw.production_year DESC, 
    absolutes.female_percentage DESC,
    mw.role_count DESC;
