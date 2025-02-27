WITH RecursiveMovieTitles AS (
    SELECT t.id AS movie_id, 
           t.title, 
           t.production_year, 
           ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
), FilteredAkaNames AS (
    SELECT DISTINCT a.name AS aka_name, 
                    a.person_id, 
                    a.md5sum 
    FROM aka_name a
    WHERE a.name IS NOT NULL AND a.name != ''
), MovieRoleCounts AS (
    SELECT c.movie_id, 
           COUNT(DISTINCT CASE WHEN r.role IS NOT NULL THEN c.person_id END) AS unique_roles_count
    FROM cast_info c
    JOIN role_type r ON c.role_id = r.id
    GROUP BY c.movie_id
), RelatedMovies AS (
    SELECT ml.movie_id, 
           ml.linked_movie_id, 
           lt.link AS link_type
    FROM movie_link ml
    JOIN link_type lt ON ml.link_type_id = lt.id
    WHERE ml.movie_id IN (SELECT DISTINCT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE phonetic_code LIKE '%Z%'))
), TitleYearStats AS (
    SELECT t.title,
           COUNT(DISTINCT c.person_id) AS total_actors,
           AVG(m.production_year) AS avg_production_year
    FROM title t
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info c ON cc.subject_id = c.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN aka_title m ON t.id = m.movie_id
    GROUP BY t.title
)
SELECT t.title, 
       t.avg_production_year,
       COALESCE(ra.movie_id, 'No Related Movies') AS related_movie_id,
       COALESCE(an.aka_name, 'Unknown Actor') AS actor_name,
       mrc.unique_roles_count
FROM TitleYearStats t
LEFT JOIN RelatedMovies ra ON ra.movie_id = (SELECT id FROM title WHERE title = t.title LIMIT 1)
LEFT JOIN FilteredAkaNames an ON an.person_id = (SELECT person_id FROM cast_info WHERE movie_id = (SELECT id FROM title WHERE title = t.title) LIMIT 1)
LEFT JOIN MovieRoleCounts mrc ON mrc.movie_id = (SELECT id FROM title WHERE title = t.title LIMIT 1)
WHERE t.total_actors > 5 AND (t.avg_production_year IS NULL OR t.avg_production_year < 2000)
ORDER BY t.avg_production_year DESC NULLS LAST, t.title;
