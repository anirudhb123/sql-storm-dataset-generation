WITH RecursiveCTE AS (
    SELECT 
        c.id AS cast_id,
        c.person_id,
        c.movie_id,
        c.person_role_id,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order,
        CASE 
            WHEN p.gender IS NULL THEN 'Unknown' 
            ELSE p.gender 
        END AS gender
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name an ON an.person_id = c.person_id
    LEFT JOIN 
        name p ON p.id = c.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'action%'))
),
AggregatedRoles AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT person_id) AS unique_cast_count,
        SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_cast_count,
        SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_cast_count
    FROM 
        RecursiveCTE
    GROUP BY 
        movie_id
),
InterestingTitles AS (
    SELECT 
        t.title,
        COALESCE(mt.info, 'No additional info') AS movie_info,
        kt.keyword AS keyword
    FROM 
        title t
    LEFT JOIN 
        movie_info mt ON mt.movie_id = t.id AND mt.info_type_id = (SELECT id FROM info_type WHERE info = 'tagline')
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kt ON kt.id = mk.keyword_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    AND 
        EXISTS (SELECT 1 FROM movie_companies mc WHERE mc.movie_id = t.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Distributor'))
)
SELECT 
    it.title,
    it.movie_info,
    ar.unique_cast_count,
    ar.female_cast_count,
    ar.male_cast_count,
    COALESCE(STRING_AGG(kt.keyword, ', '), 'No Keywords') AS keywords,
    CASE 
        WHEN ar.unique_cast_count = 0 THEN 'No cast information'
        WHEN ar.male_cast_count > ar.female_cast_count THEN 'More Male Cast'
        WHEN ar.female_cast_count > ar.male_cast_count THEN 'More Female Cast'
        ELSE 'Equal Cast'
    END AS cast_gender_balance
FROM 
    InterestingTitles it
JOIN 
    AggregatedRoles ar ON ar.movie_id = it.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = it.id
LEFT JOIN 
    keyword kt ON kt.id = mk.keyword_id
GROUP BY 
    it.title, it.movie_info, ar.unique_cast_count, ar.female_cast_count, ar.male_cast_count
ORDER BY 
    ar.unique_cast_count DESC, it.title;

This SQL query is designed to perform several tasks involving various SQL constructs while focusing on the performance of movie data related to action keywords and providing insights into the demographics of cast members. It uses CTEs for clarity, includes outer joins to gather related data, and employs CASE statements to handle NULL logic and conditional aggregation. The recursive CTE and window functions are leveraged for analyzing casting data, while also ensuring that the output contains informative and interesting results based on the specifications provided.
