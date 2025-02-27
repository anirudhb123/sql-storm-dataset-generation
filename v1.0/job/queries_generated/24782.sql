WITH Recursive_Cast AS (
    SELECT
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ci.person_role_id,
        ci.role_id,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM cast_info ci
),
Top_Movies AS (
    SELECT
        ak.title,
        ak.production_year,
        COUNT(DISTINCT ca.person_id) AS cast_count
    FROM aka_title ak
    JOIN cast_info ca ON ak.movie_id = ca.movie_id
    WHERE ak.production_year IS NOT NULL
    GROUP BY ak.title, ak.production_year
    HAVING COUNT(DISTINCT ca.person_id) > 5
    ORDER BY cast_count DESC
    LIMIT 10
),
Movie_Details AS (
    SELECT
        tm.title,
        tm.production_year,
        STRING_AGG(CONCAT(cast_id, ': ', COALESCE(p.name, 'Unknown')), ', ') AS cast_list,
        CASE
            WHEN m.kid IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS has_keyword
    FROM Top_Movies tm
    LEFT JOIN Recursive_Cast rc ON tm.title = rc.movie_id
    LEFT JOIN person_info pi ON rc.person_id = pi.person_id
    LEFT JOIN (SELECT DISTINCT movie_id, keyword_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword = 'action')) m ON tm.title = m.movie_id
    GROUP BY tm.title, tm.production_year, m.kid
),
Critical_Movies AS (
    SELECT
        md.title,
        md.production_year,
        md.cast_list,
        md.has_keyword,
        COALESCE(pi.info, 'No additional info') AS additional_info
    FROM Movie_Details md
    LEFT JOIN person_info pi ON pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Critical Review')
    WHERE md.has_keyword = 'Yes'
)
SELECT
    cm.title,
    cm.production_year,
    cm.cast_list,
    cm.has_keyword,
    CASE
        WHEN md.title IS NULL THEN 'No Related Movies'
        ELSE STRING_AGG(md.title, '; ')
    END AS related_movies
FROM Critical_Movies cm
LEFT JOIN movie_link ml ON ml.movie_id = (SELECT id FROM aka_title WHERE title = cm.title AND production_year = cm.production_year)
LEFT JOIN aka_title md ON ml.linked_movie_id = md.id
GROUP BY cm.title, cm.production_year, cm.cast_list, cm.has_keyword
ORDER BY cm.production_year DESC, cm.title;
