WITH RecursiveDirector AS (
    SELECT DISTINCT c.person_id, 
           ARRAY_AGG(DISTINCT CONCAT(a.name, ' (', r.role, ')')) AS director_names
    FROM cast_info c
    JOIN role_type r ON r.id = c.person_role_id
    JOIN aka_name a ON a.person_id = c.person_id
    WHERE r.role ILIKE '%director%'
    GROUP BY c.person_id
),
MovieTitleYear AS (
    SELECT t.title, 
           t.production_year, 
           ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM title t
    LEFT JOIN movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN keyword k ON k.id = mk.keyword_id
    GROUP BY t.title, t.production_year
),
DirectorMovie AS (
    SELECT d.person_id, 
           mt.title, 
           mt.production_year, 
           d.director_names
    FROM RecursiveDirector d
    JOIN cast_info c ON c.person_id = d.person_id
    JOIN MovieTitleYear mt ON mt.id = c.movie_id
)
SELECT dm.person_id, 
       dm.title, 
       dm.production_year, 
       dm.director_names,
       CASE 
           WHEN dm.production_year < 2000 THEN 'Classic'
           WHEN dm.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
           ELSE 'Recent'
       END AS era,
       (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = dm.movie_id) AS info_count,
       (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = dm.movie_id) AS company_count
FROM DirectorMovie dm
ORDER BY dm.production_year DESC, dm.title;
