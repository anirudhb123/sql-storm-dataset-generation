WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS most_cast,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.id
    GROUP BY t.id, t.title, t.production_year
), 
PopularRoles AS (
    SELECT 
        ci.role_id,
        rt.role,
        COUNT(*) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.role_id, rt.role
    HAVING COUNT(*) > 5  -- Only consider roles with more than 5 appearances
), 
MovieStats AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        COALESCE(SUM(mi.info_type_id = 1), 0) AS has_box_office_info,  -- Assuming info_type_id = 1 is for box office
        MAX(t.production_year) AS latest_year,
        AVG(EXTRACT(YEAR FROM AGE(NOW(), t.production_year))) AS avg_age
    FROM title t
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    GROUP BY t.id, t.title
)

SELECT 
    rt.title, 
    rt.production_year, 
    rt.total_cast,
    mr.role,
    mp.movie_id,
    mp.has_box_office_info,
    mp.latest_year,
    mp.avg_age,
    CASE 
        WHEN mp.has_box_office_info > 0 THEN 'Yes'
        ELSE 'No'
    END AS box_office_availability
FROM RankedTitles rt
JOIN PopularRoles mr ON rt.most_cast = mr.role_count
JOIN MovieStats mp ON rt.title_id = mp.movie_id
WHERE rt.production_year IS NOT NULL 
  AND mp.latest_year IS NOT NULL 
  AND rt.total_cast > 0
ORDER BY rt.production_year DESC, rt.total_cast DESC
LIMIT 10;

